//
//  GradesTermTableViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/12/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

protocol GradesTermSelectorDelegate {
    var term : GradeTerm? { get set }
}

class GradesTermTableViewController : UITableViewController, GradesTermSelectorDelegate, NSFetchedResultsControllerDelegate, EllucianMobileLaunchableControllerProtocol {
    
    var module : Module?
    @IBOutlet var termsButton: UIBarButtonItem! //iPhone Only
    var term : GradeTerm?
    let dateFormatterLastUpdatedHeader : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
        }()
    var _fetchedResultsController: NSFetchedResultsController<GradeTerm>?
    
    override func viewDidLoad() {
        termsButton.isEnabled = false
        if let splitViewController = splitViewController {
            //iPad
            self.navigationController!.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            self.navigationController!.topViewController!.navigationItem.leftItemsSupplementBackButton = true
            
            var rightButtonItems = self.navigationItem.rightBarButtonItems
            rightButtonItems?.removeFirst()
            self.navigationItem.rightBarButtonItems = rightButtonItems
        } else {
            //iPhone
            sendView("Grades List", moduleName: self.module?.name)
            self.title = self.module?.name
            if let sections = fetchedResultsController.sections {
                let currentSection = sections[0] as NSFetchedResultsSectionInfo
                let count = currentSection.numberOfObjects
                if count > 0 {
                    self.selectFirst()
                }
            }

            fetchGrades()
        }
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let _ = term {
            self.tableView.reloadData()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let term = term, let courses = term.courses {
            return courses.count + 1
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if term == nil {
                return 1
            }
            if let count = term?.courses?.count , count > 0 {
                return 1
            } else {
                return 2
            }
        default:
            let course = term!.courses[section - 1] as! GradeCourse
            let count = course.grades.count
            if count == 0 {
                return 2
            }
            else {
                return count + 1
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.layoutMargins = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch ((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row, term) {
        case (_, _, nil):
            return tableView.dequeueReusableCell(withIdentifier: "No Grades Cell", for: indexPath) as UITableViewCell
        case (0, 0, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Term Name Cell", for: indexPath) as UITableViewCell
            
            let termLabel = cell.viewWithTag(1) as! UILabel
            
            termLabel.text = term!.name
            return cell
        case (_, 0, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Course Name Cell", for: indexPath) as UITableViewCell
            
            let course = term!.courses[(indexPath as NSIndexPath).section - 1] as! GradeCourse
            let courseLabel = cell.viewWithTag(1) as! UILabel
            let titleLabel = cell.viewWithTag(2) as! UILabel

            if let courseName = course.courseName, let courseSectionNumber = course.courseSectionNumber {
                courseLabel.text = String(format: "%@-%@", courseName, courseSectionNumber)
            } else if let courseName = course.courseName {
                courseLabel.text = courseName
            } else if let courseSectionNumber = course.courseSectionNumber {
                courseLabel.text = courseSectionNumber
            } else {
                courseLabel.text = ""
            }
            
            titleLabel.text = course.sectionTitle
            return cell
        
        default :
            if let courses = term!.courses , courses.count > 0 {
                let course = term!.courses[(indexPath as NSIndexPath).section - 1] as! GradeCourse
                if course.grades.count > 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "Grade Cell", for: indexPath) as UITableViewCell
                    let grade = course.grades[(indexPath as NSIndexPath).row - 1] as! Grade
                    
                    let descriptionLabel = cell.viewWithTag(1) as! UILabel
                    let lastUpdatedLabel = cell.viewWithTag(2) as! UILabel
                    let gradeLabel = cell.viewWithTag(3) as! UILabel
                    
                    descriptionLabel.text = grade.name
                    
                    if let date = grade.lastUpdated {
                        let formattedDate = self.dateFormatterLastUpdatedHeader.string(from: date)
                        lastUpdatedLabel.text = String(format: NSLocalizedString("Last Updated %@", comment: "Last Updated date"), formattedDate)
                    } else {
                        lastUpdatedLabel.text = NSLocalizedString("Last Updated Unknown", comment: "Last Updated date unknown")
                    }
                    
                    gradeLabel.text = grade.value
                    return cell
                } else {
                    return tableView.dequeueReusableCell(withIdentifier: "No Grades Cell", for: indexPath) as UITableViewCell
                }

            } else {
                 return tableView.dequeueReusableCell(withIdentifier: "No Grades Cell", for: indexPath) as UITableViewCell
            }
            
        }
    
    }
    
    func fetchGrades() {
        let operation = GradesFetchOperation(module: module, view: self)
        
        
        if self.fetchedResultsController.fetchedObjects!.count <= 0 {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
            hud.label.text = loadingString
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        }
        
        OperationQueue.main.addOperation(operation)
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Filter" {
            let detailController = (segue.destination as! UINavigationController).topViewController as! GradesTermFilterViewController
            detailController.delegate = self
            detailController.module = self.module
        }
    }
    
    // MARK: fetch
    var fetchedResultsController: NSFetchedResultsController<GradeTerm> {
        // return if already initialized
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
        
        let request = NSFetchRequest<GradeTerm>(entityName: "GradeTerm")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
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
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.selectFirst()
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    func selectFirst() {
        let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
        let request = NSFetchRequest<GradeTerm>( entityName: "GradeTerm")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        let terms = try? managedObjectContext.fetch(request)
        if let terms = terms , terms.count > 0 {
            termsButton.isEnabled = true

            self.term = terms[0]
            self.tableView.reloadData()
        }
    }

}
