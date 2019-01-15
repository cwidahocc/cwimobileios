//
//  ScheduleViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 10/14/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class ScheduleViewController : UITableViewController, ScheduleTermSelectedDelegate, EllucianMobileLaunchableControllerProtocol {
    
    var module : Module!
    var terms : [CourseTerm]?
    var selectedTerm = 0
    let dateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    var hud : MBProgressHUD!
    
    @IBOutlet var termsButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.module?.name
        
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
        hud.label.text = loadingString
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        fetchSchedule()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSchedule()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sendView( "Schedule (full schedule)", moduleName: self.module?.name)
    }
    
    func loadSchedule() {
        
        let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
        
        let fetchRequest = NSFetchRequest<CourseTerm>(entityName: "CourseTerm")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        self.terms = try? managedObjectContext.fetch(fetchRequest) 
        self.reload()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let terms = self.terms , terms.count > section {
            return terms[selectedTerm].sections.count
        }
        return 0
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let terms = self.terms , terms.count > 0 {
            return 1
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Schedule Cell", for: indexPath) as UITableViewCell
        
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.accessibilityHint = NSLocalizedString("Displays course detail.", comment:"VoiceOver hint for button that displays a course's details")
        
        let courseNameLabel = cell.viewWithTag(1) as! UILabel
        let sectionTitleLabel = cell.viewWithTag(2) as! UILabel
        if let section = self.terms![selectedTerm].sections[(indexPath as NSIndexPath).row] as? CourseSection {
            
            if let courseName = section.courseName, let courseSectionNumber = section.courseSectionNumber {
                courseNameLabel.text = "\(courseName)-\(courseSectionNumber)"
            }
            if let sectionTitle = section.sectionTitle {
                sectionTitleLabel.text = sectionTitle
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.sendEventToTracker1(category: .ui_Action, action: .list_Select, label: "Click Course", moduleName: self.module?.name)
        let term = self.terms![selectedTerm]
        let section = term.sections[(indexPath as NSIndexPath).row]
        
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "Show Course Detail", sender: section)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "Show Course Detail" {
            if let course = sender as? CourseSection {
                let tabBarController = segue.destination as! CourseDetailTabBarController
                tabBarController.isInstructor = course.isInstructor as? Bool
                tabBarController.module = self.module!
                tabBarController.termId = course.term.termId
                tabBarController.sectionId = course.sectionId
                tabBarController.courseName = course.courseName
                tabBarController.courseSectionNumber = course.courseSectionNumber
                
                for v in tabBarController.viewControllers! {
                    var vc: UIViewController = v
                    if let navVC = v as? UINavigationController {
                        vc = navVC.viewControllers[0]
                    }
                    if let vc = vc as? CourseDetailViewControllerProtocol {
                        vc.module = self.module
                        vc.sectionId = course.sectionId
                        vc.termId = course.term.termId
                        vc.courseName = course.courseName
                        vc.courseSectionNumber = course.courseSectionNumber
                    }
                }
            }
        }  else if segue.identifier == "Choose Courses Term" {
            let navController = segue.destination as! UINavigationController
            let detailController = navController.viewControllers[0] as! CoursesPageSelectionViewController
            detailController.terms = self.terms
            detailController.coursesChangePageDelegate = self
            detailController.module = self.module
            
        }
    }
    
    func fetchSchedule() {
        if let userid = CurrentUser.sharedInstance.userid {
            let urlBase = self.module?.property(forKey: "full")
            let urlString = "\(urlBase!)/\(userid.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)"
            
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.parent = self.module?.managedObjectContext
            privateContext.undoManager = nil
            
            privateContext.perform { () -> Void in
                
                do {
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    }
                    let authenticatedRequest = AuthenticatedRequest()
                    if let url = URL(string: urlString) {
                        if let responseData = authenticatedRequest.requestURL(url, fromView: self) {
                            let json = JSON(data: responseData)
                            DispatchQueue.main.async {
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            }
                            
                            let termRequest = NSFetchRequest<CourseTerm>(entityName: "CourseTerm")
                            let oldObjects = try privateContext.fetch(termRequest)
                            for oldObject in oldObjects {
                                privateContext.delete(oldObject)
                            }
                            
                            if let jsonTerms = json["terms"].array {
                                
                                for termJson in jsonTerms {
                                    let term = NSEntityDescription.insertNewObject(forEntityName: "CourseTerm", into: privateContext) as! CourseTerm
                                    term.termId = termJson["id"].string
                                    term.name = termJson["name"].string
                                    term.startDate = self.dateFormatter.date(from: termJson["startDate"].string!)
                                    term.endDate = self.dateFormatter.date(from: termJson["endDate"].string!)
                                    
                                    for courseJson in termJson["sections"].array! {
                                        
                                        let course = NSEntityDescription.insertNewObject(forEntityName: "CourseSection", into: privateContext) as! CourseSection
                                        course.sectionId = courseJson["sectionId"].string
                                        course.sectionTitle = courseJson["sectionTitle"].string
                                        course.isInstructor = NSNumber(value: courseJson["isInstructor"].int32!)
                                        course.courseName = courseJson["courseName"].string
                                        course.courseSectionNumber = courseJson["courseSectionNumber"].string
                                        term.addSectionsObject(course)
                                        course.term = term
                                        
                                    }
                                }
                            }
                            try privateContext.save()
                            
                            privateContext.parent?.perform({
                                do {
                                    try privateContext.parent?.save()
                                } catch let error {
                                    print (error)
                                }
                            })
                            
                            DispatchQueue.main.async(execute: {
                                self.loadSchedule()
                            })
                        } else {
                            DispatchQueue.main.async(execute: {
                                let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment:"title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment:"message when data cannot load due to a poor netwrok connection"), preferredStyle: .alert)
                                let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: UIAlertActionStyle.default)
                                alertController.addAction(alertAction)
                                self.present(alertController, animated: true)
                            })
                        }
                    }
                    DispatchQueue.main.async(execute: {
                        self.hud.hide(animated: true)
                    })
                } catch let error {
                    print (error)
                    DispatchQueue.main.async(execute: {
                        self.hud.hide(animated: true)
                    })
                }
                
            }
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
        let label = UILabel(frame: CGRect(x: 8,y: 0,width: tableView.frame.width, height: 30))
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let term = self.terms![selectedTerm]
        label.text = term.name
        
        
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        view.backgroundColor = UIColor(rgba: "#e6e6e6")
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        
        view.addSubview(label)
        
        let viewsDictionary = ["label": label, "view": view]
        
        // Create and add the vertical constraints
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-1-[label]-1-|",
            options: .alignAllLastBaseline,
            metrics: nil,
            views: viewsDictionary))
        
        // Create and add the horizontal constraints
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[label]",
            options: .alignAllLastBaseline,
            metrics: nil,
            views: viewsDictionary))
        return view;
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    
    func reload() {
        self.tableView.reloadData()
        if let terms = terms , terms.count > 0 {
            self.termsButton.isEnabled = true
        }
    }
    
}
