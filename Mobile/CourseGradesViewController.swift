//
//  CourseGradesViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 10/29/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class CourseGradesViewController : UITableViewController, NSFetchedResultsControllerDelegate, CourseDetailViewControllerProtocol {
    
    var module : Module?
    var termId : String?
    var sectionId : String?
    var courseName : String?
    var courseSectionNumber : String?

    var _fetchedResultsController : NSFetchedResultsController<Grade>?
    
    let dateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    let datetimeFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation:"UTC")
        return formatter
    }()
    let datetimeOutputFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        try! self.fetchedResultsController.performFetch()
        self.navigationItem.title = self.courseNameAndSectionNumber()
        if CurrentUser.sharedInstance.isLoggedIn {
            self.fetchGrades(self)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(CourseGradesViewController.fetchGrades(_:)), name: CurrentUser.LoginExecutorSuccessNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sendView("Course grades", moduleName: self.module!.name)
    }
    
    var fetchedResultsController: NSFetchedResultsController<Grade> {
        // return if already initialized
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = self.module!.managedObjectContext!
        
        let request = NSFetchRequest<Grade>(entityName: "Grade")
        request.predicate = NSPredicate(format: "course.sectionId == %@ and course.term.termId == %@", self.sectionId!, self.termId!)
        request.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        self._fetchedResultsController = aFetchedResultsController
        
        do {
            try self._fetchedResultsController!.performFetch()
            
        } catch let error {
            print("fetch error: \(error)")
        }
        
        return self._fetchedResultsController!
    }
    
    @IBAction func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as NSFetchedResultsSectionInfo
            let count = currentSection.numberOfObjects
            if count > 0 {
                return count
            } else {
                return 1
            }
        }
        
        return 1
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let fetchedObjectsCount = fetchedResultsController.fetchedObjects?.count, fetchedObjectsCount > 0 {
            
            let grade = fetchedResultsController.object(at: indexPath)
            let cell = tableView.dequeueReusableCell(withIdentifier: "Grade Cell", for: indexPath) as UITableViewCell
            
            
            let descriptionLabel = cell.viewWithTag(1) as! UILabel
            let lastUpdatedLabel = cell.viewWithTag(2) as! UILabel
            let gradeLabel = cell.viewWithTag(3) as! UILabel
            
            descriptionLabel.text = grade.name
            
            if let date = grade.lastUpdated { //todo :  where date != nil {
                let formattedDate = self.datetimeOutputFormatter.string(from: date)
                lastUpdatedLabel.text = String(format: NSLocalizedString("Last Updated %@", comment: "Last Updated date"), formattedDate)
            } else {
                lastUpdatedLabel.text = NSLocalizedString("Last Updated Unknown", comment: "Last Updated date unknown")
            }
            
            gradeLabel.text = grade.value
            return cell
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "No Grades Cell", for: indexPath) as UITableViewCell
        }
    }
    
    
    @objc func fetchGrades(_ sender: AnyObject) {
        
        
        if let userid = CurrentUser.sharedInstance.userid {
            let urlBase = self.module?.property(forKey: "grades")
            let escapedUserId = userid.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let escapedTermId = self.termId?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let escapedSectionId = self.sectionId?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let urlString = "\(urlBase!)/\(escapedUserId!)?term=\(escapedTermId!)&section=\(escapedSectionId!)"
            
            if self.fetchedResultsController.fetchedObjects!.count <= 0 {
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
                hud.label.text = loadingString
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
            }
            
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.parent = self.module!.managedObjectContext
            privateContext.undoManager = nil
            
            privateContext.perform { () -> Void in
                
                do {
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    }
                    
                    defer {
                        DispatchQueue.main.async {
                            
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            MBProgressHUD.hide(for: self.view, animated: true)
                        }
                    }
                    
                    let authenticatedRequest = AuthenticatedRequest()
                    if let responseData = authenticatedRequest.requestURL(URL(string: urlString)!, fromView: self) {
                        let json = JSON(data: responseData)
                        DispatchQueue.main.async {
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                        
                        let request = NSFetchRequest<GradeTerm>(entityName: "GradeTerm")
                        request.predicate = NSPredicate(format: "termId == %@", self.termId!)
                        let terms = try privateContext.fetch(request)
                        
                        if let jsonTerms = json["terms"].array {
                            for jsonTerm in jsonTerms {
 
                                let filtered = terms.filter {
                                    let x = $0 as GradeTerm
                                    return x.termId == self.termId
                                }
                                let gradeTerm : GradeTerm
                                if filtered.count > 0 {
                                    gradeTerm = filtered.first!
                                } else {
                                    gradeTerm = NSEntityDescription.insertNewObject(forEntityName: "GradeTerm", into: privateContext) as! GradeTerm
                                    gradeTerm.termId = jsonTerm["id"].string
                                    gradeTerm.name = jsonTerm["name"].string
                                    gradeTerm.startDate = self.dateFormatter.date(from: jsonTerm["startDate"].string!)
                                    gradeTerm.endDate = self.dateFormatter.date(from: jsonTerm["endDate"].string!)
                                }
                                if let jsonSections = jsonTerm["sections"].array {
                                    for jsonSection in jsonSections {
                                        let courses = gradeTerm.courses
                                        let filtered = courses!.filter {
                                            let x = $0 as! GradeCourse
                                            return x.sectionId == self.sectionId
                                        }
                                        let gradeCourse : GradeCourse
                                        if filtered.count > 0 {
                                            gradeCourse = filtered.first as! GradeCourse
                                        } else {
                                            gradeCourse = NSEntityDescription.insertNewObject(forEntityName: "GradeCourse", into: privateContext) as! GradeCourse
                                            gradeCourse.sectionId = jsonSection["sectionId"].string
                                            gradeCourse.courseName = jsonSection["courseName"].string
                                            gradeCourse.sectionTitle = jsonSection["sectionTitle"].string
                                            gradeCourse.courseSectionNumber = jsonSection["courseSectionNumber"].string
                                            gradeCourse.term = gradeTerm
                                            gradeTerm.addCoursesObject(gradeCourse)
                                        }
                                        
                                        for oldObject in gradeCourse.grades {
                                            privateContext.delete(oldObject as! Grade)
                                        }
                                        
                                        if let jsonGrades = jsonSection["grades"].array {
                                            for jsonGrade in jsonGrades {
                                                let grade = NSEntityDescription.insertNewObject(forEntityName: "Grade", into: privateContext) as! Grade
                                                grade.name = jsonGrade["name"].string
                                                grade.value = jsonGrade["value"].string
                                                if let lastUpdated = jsonGrade["updated"].string {
                                                    grade.lastUpdated = self.datetimeFormatter.date(from: lastUpdated)
                                                }
                                                gradeCourse.addGradesObject(grade)
                                                grade.course = gradeCourse
                                                
                                            }
                                        }
                                        
                                    }
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
                            self._fetchedResultsController = nil;
                            try! self.fetchedResultsController.performFetch()
                            self.tableView.reloadData()
                        })
                    } else {
                        DispatchQueue.main.async(execute: {
                            let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment:"title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment:"message when data cannot load due to a poor netwrok connection"), preferredStyle: .alert)
                            let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: UIAlertActionStyle.default)
                            alertController.addAction(alertAction)
                            self.present(alertController, animated: true)
                        })
                    }
                } catch let error {
                    print (error)
                }
                
            }
        }
        
    }
    
    
}
