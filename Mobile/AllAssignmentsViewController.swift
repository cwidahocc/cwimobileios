//
//  AllAssignmentsViewController.swift
//  Mobile
//
//  Created by Alan McEwan on 2/3/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation


class AllAssignmentsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISplitViewControllerDelegate, EKEventEditViewDelegate, EllucianMobileLaunchableControllerProtocol, MasterWithDetailSelectionDelegateProtocol, ILPAllItemsViewControllerProtocol
{
    @IBOutlet weak var dateSelector: UISegmentedControl!
    @IBOutlet weak var myTabBarItem: UITabBarItem!
    @IBOutlet var allAssignmentsTableView: UITableView!
    
    var detailSelectionDelegate: DetailSelectionDelegate!
    var allAssignmentController: NSFetchedResultsController<CourseAssignment>!
    var myDatetimeOutputFormatter: DateFormatter?
    var myOverDueDatetimeOutputFormatter: DateFormatter?
    var myTabBarController: UITabBarController!
    var module: Module!
    var detailViewController: CourseAssignmentDetailViewController!
    var selectedAssignment:CourseAssignment?
    var selectedIndex:NSInteger = 0
    var overdueRed:UIColor?
    
    var showHeaders: Bool = true
    
    var myManagedObjectContext: NSManagedObjectContext!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.extendedLayoutIncludesOpaqueBars = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UIDevice.current.userInterfaceIdiom == .pad {
            findSelectedItem()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allAssignmentController = getAssignmentsFetchedResultsController(true)
        do {
            try allAssignmentController.performFetch()
        } catch let assignmentError as NSError {
            print("fetch error: \(assignmentError.localizedDescription)")
        }
        allAssignmentsTableView.register(NSClassFromString("UITableViewHeaderFooterView"), forHeaderFooterViewReuseIdentifier: "Header")
        
        self.view.backgroundColor = UIColor.primary
        let tabBarItem0 = myTabBarController?.tabBar.items?[0]
        if let tabBarItem0 = tabBarItem0 {
            tabBarItem0.selectedImage = UIImage(named: "ilp-assignments-selected")
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if selectedAssignment == nil {
                if allAssignmentController.fetchedObjects!.count > 0 {
                    let indexPath = IndexPath(row: 0, section: 0)
                    allAssignmentsTableView.selectRow(at: indexPath, animated: true, scrollPosition:UITableViewScrollPosition.top)
                    tableView(self.allAssignmentsTableView, didSelectRowAt: indexPath);
                }
            }
        }
        self.sendEventToTracker1(category: .ui_Action, action: .search, label:"ILP Assignments List", moduleName: "ILP");
        overdueRed = UIColor(red: 193.0/255.0, green: 39.0/255.0, blue: 45.0/255.0, alpha: 1.0)
    }
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        
        switch dateSelector.selectedSegmentIndex
        {
        case 0:
            allAssignmentController = getAssignmentsFetchedResultsController(true)
            do {
                try allAssignmentController.performFetch()
            } catch let assignmentError as NSError {
                print("Unresolved error: fetch error: \(assignmentError.localizedDescription)")
            }
        case 1:
            allAssignmentController = getAssignmentsFetchedResultsController(false)
            do {
                try allAssignmentController.performFetch()
            } catch let assignmentError as NSError {
                print("Unresolved error: fetch error: \(assignmentError.localizedDescription)")
            }
        default:
            break
        }
        
        allAssignmentsTableView.reloadData()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if allAssignmentController.fetchedObjects!.count > 0 {
                let indexPath = IndexPath(row: 0, section: 0)
                allAssignmentsTableView.selectRow(at: indexPath, animated: true, scrollPosition:UITableViewScrollPosition.top)
                tableView(self.allAssignmentsTableView, didSelectRowAt: indexPath);
            }
        }
        
    }
    
    /* called first
    begins update to `UITableView`
    ensures all updates are animated simultaneously */
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        allAssignmentsTableView.beginUpdates()
    }
    
    /* helper method to configure a `UITableViewCell`
    ask `NSFetchedResultsController` for the model */
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        
        var isOverdue = false
        var sectionName:String = ""
        
        if let sections = allAssignmentController!.sections {
            let name = sections[(indexPath as NSIndexPath).section].name
            sectionName =  name
        }
        
        if sectionName == NSLocalizedString("OVERDUE", comment:"overdue assignment indicator for ilp module") {
            isOverdue = true
        }
        
        let assignment = allAssignmentController.object(at: indexPath)
        let nameLabel = cell.viewWithTag(100) as! UILabel
        nameLabel.text = assignment.name
        
        let sectionNameLabel = cell.viewWithTag(101) as! UILabel
        sectionNameLabel.text = assignment.courseName + "-" + assignment.courseSectionNumber
        
        let dueDateLabel = cell.viewWithTag(102) as! UILabel
        
        if let assignmentDate = assignment.dueDate {
            dueDateLabel.text = self.datetimeOutputFormatter()!.string(from: assignmentDate)
        } else {
            dueDateLabel.text = ""
        }
        
        if isOverdue {
            nameLabel.textColor = overdueRed
        } else {
            nameLabel.textColor = UIColor.black
        }
        
    }
    
    /* called:
    - when a new model is created
    - when an existing model is updated
    - when an existing model is deleted */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {            
            switch type {
            case .insert:
                allAssignmentsTableView.insertRows(at: [newIndexPath as IndexPath!], with: .fade)
            case .update:
                let cell = self.allAssignmentsTableView.cellForRow(at: indexPath as IndexPath!)
                configureCell(cell!, atIndexPath: indexPath as IndexPath!)
                allAssignmentsTableView.reloadRows(at: [indexPath as IndexPath!], with: .fade)
            case .delete:
                allAssignmentsTableView.deleteRows(at: [indexPath as IndexPath!], with: .fade)
            default:
                break
            }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType)
    {
        switch(type) {
            
        case .insert:
            allAssignmentsTableView.insertSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
            
        case .delete:
            allAssignmentsTableView.deleteSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
            
        default:
            break
        }
    }
    
    /* called last
    tells `UITableView` updates are complete */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        allAssignmentsTableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Daily Assignment Cell", for: indexPath) as UITableViewCell
        cell.accessibilityTraits = UIAccessibilityTraitButton
        configureCell(cell, atIndexPath:indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let assignment = allAssignmentController.object(at: indexPath)
            selectedAssignment = assignment
            
            detailViewController.courseName = assignment.courseName
            detailViewController.courseSectionNumber = assignment.courseSectionNumber
            detailViewController.itemTitle = assignment.name
            detailViewController.itemContent = assignment.assignmentDescription
            detailViewController.itemLink = assignment.url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if let assignmentDate = assignment.dueDate {
                detailViewController.itemPostDateTime = assignmentDate
            }
            else {
                detailViewController.itemPostDateTime = nil
            }
            self.detailSelectionDelegate = detailViewController
            self.detailSelectionDelegate.selectedDetail(assignment, withIndex: indexPath, with: self.module!, withController: self)
            
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            self.performSegue(withIdentifier: "Show ILP Assignment Detail", sender:tableView)
        }
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        
        let count = allAssignmentController.sections?.count
        
        if count == 0 || !showHeaders {
            return 0.0
        } else {
            //return 18.0
            return 30.0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        let numberOfSections = allAssignmentController.sections?.count
        return numberOfSections!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let numberOfRowsInSection = allAssignmentController.sections?[section].numberOfObjects
        return numberOfRowsInSection!
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let sections = allAssignmentController.sections
        let dateLabel:String? = sections?[section].name
        var header:UITableViewCell
        
        if dateLabel == NSLocalizedString("OVERDUE", comment:"overdue assignment indicator for ilp module") {
            header = tableView.dequeueReusableCell(withIdentifier: "OverdueSectionHeader")!
        } else {
            header = tableView.dequeueReusableCell(withIdentifier: "SectionHeader")!
        }
        
        header.contentView.backgroundColor = UIColor.accent
        let labelView = header.viewWithTag(101) as! UILabel
        labelView.text = dateLabel
        labelView.sizeToFit()
        return header
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "Show ILP Assignment Detail" {
            let indexPath: IndexPath! = allAssignmentsTableView.indexPathForSelectedRow
            let assignment = allAssignmentController.object(at: indexPath)
            let detailController = segue.destination as! CourseAssignmentDetailViewController
            detailController.courseSectionNumber = assignment.courseSectionNumber
            detailController.courseName = assignment.courseName
            detailController.itemTitle = assignment.name
            
            detailController.itemContent = assignment.assignmentDescription
            
            if let url = assignment.url {
                detailController.itemLink = url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } else {
                detailController.itemLink = nil
            }
            
            if let assignmentDate = assignment.dueDate {
                detailController.itemPostDateTime = assignmentDate
            }
            else {
                detailController.itemPostDateTime = nil
            }
            allAssignmentsTableView.deselectRow(at: indexPath, animated: true)
        } else if segue.identifier == "Edit Reminder"{
            let detailController = segue.destination.childViewControllers[0] as! EditReminderViewController
            
            detailController.reminderTitle = reminderAssignment!.name
            
            if let date = reminderAssignment!.dueDate {
                detailController.reminderDate = date
                let formattedDate = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
                let localizedDue = String.localizedStringWithFormat(NSLocalizedString("Due: %@", comment: "due date label with date"), formattedDate)
                
                var reminderString = ""
                if let courseName = reminderAssignment!.courseName {
                    reminderString += "\(courseName)"
                }
                if let courseSectionNumber = reminderAssignment!.courseSectionNumber {
                    reminderString += "-\(courseSectionNumber)"
                }
                reminderString += "\n\(localizedDue)"
                if let assignmentDescription = reminderAssignment!.assignmentDescription {
                    reminderString += "\n\(assignmentDescription)"
                }
                
                detailController.reminderNotes = reminderString
            } else {
                var reminderString = ""
                if let courseName = reminderAssignment!.courseName {
                    reminderString += "\(courseName)"
                }
                if let courseSectionNumber = reminderAssignment!.courseSectionNumber {
                    reminderString += "-\(courseSectionNumber)"
                }
                if let assignmentDescription = reminderAssignment!.assignmentDescription {
                    reminderString += "\n\(assignmentDescription)"
                }
                detailController.reminderNotes = reminderString
            }
            
            
        }
    }
    
    func assignmentFetchRequest(_ showOnlyItemsWithDates:Bool) -> NSFetchRequest<CourseAssignment> {
        
        let fetchRequest = NSFetchRequest<CourseAssignment>(entityName: "CourseAssignment")
        var fetchPredicate:NSPredicate!
        
        if (showOnlyItemsWithDates) {
            fetchPredicate = NSPredicate(format: "dueDate != nil")
        } else {
            fetchPredicate = NSPredicate(format: "dueDate == nil")
        }
        
        let sortDescriptor = NSSortDescriptor(key:"dueDate", ascending:true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = fetchPredicate
        return fetchRequest
    }
    
    func getAssignmentsFetchedResultsController(_ showOnlyItemsWithDates: Bool) -> NSFetchedResultsController<CourseAssignment> {
        
        showHeaders = showOnlyItemsWithDates
        
        let importContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        importContext.parent = self.myManagedObjectContext
        
        let fetchRequest = assignmentFetchRequest(showOnlyItemsWithDates)
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: "CourseAssignment", in:importContext)
        fetchRequest.entity = entity;
        
        var theFetchedResultsController:NSFetchedResultsController<CourseAssignment>!
        
        if showOnlyItemsWithDates {
            theFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:importContext, sectionNameKeyPath:"displayDateSectionHeader", cacheName:nil)
        } else {
            theFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:importContext, sectionNameKeyPath:nil, cacheName:nil)
        }
        
        return theFetchedResultsController
        
    }
    
    func datetimeOutputFormatter() ->DateFormatter? {
        
        if (myDatetimeOutputFormatter == nil) {
            myDatetimeOutputFormatter = DateFormatter()
            myDatetimeOutputFormatter!.timeStyle = .short
            myDatetimeOutputFormatter!.dateStyle = .short
        }
        return myDatetimeOutputFormatter
    }
    
    //    func setSelectedAssignment(item:CourseAssignment?)
    //    {
    //        selectedAssignment = item
    //    }
    
    func findSelectedItem() {
        
        if let myTargetItem = selectedAssignment {
            var indexPath = IndexPath(row: 0, section: 0)
            
            for iter in allAssignmentController.fetchedObjects!
            {
                let temp: CourseAssignment = iter
                if myTargetItem.url != nil && temp.url == myTargetItem.url {
                    indexPath = allAssignmentController.indexPath(forObject: temp)!
                }
            }
            allAssignmentsTableView.selectRow(at: indexPath, animated: true, scrollPosition:UITableViewScrollPosition.top)
            tableView(self.allAssignmentsTableView, didSelectRowAt: indexPath);
        }
    }
    
    var reminderAssignment : CourseAssignment? = nil
    
    @IBAction func addReminderTapped(_ sender: AnyObject) {
        let buttonPosition = sender.convert(CGPoint.zero, to: self.allAssignmentsTableView);
        let indexPath = self.allAssignmentsTableView.indexPathForRow(at: buttonPosition);
        if let indexPath = indexPath {
            reminderAssignment = allAssignmentController.object(at: indexPath)
            
            let reminderType = UserDefaults.standard.string(forKey: "settings-assignments-reminder")
            if reminderType == "Calendar" {
                addToCalendar()
            } else if reminderType == "Reminders" {
                addToReminders()
            } else {
                
                let alertController = UIAlertController(title: NSLocalizedString("Reminder Type", comment:"Reminder setting title"), message: NSLocalizedString("What application would you like to use for reminders?", comment:"Reminder setting message"), preferredStyle: .alert)

                let calendarAction = UIAlertAction(title: NSLocalizedString("Calendar", comment:"Calendar app name"), style: .default) { (action) in
                    UserDefaults.standard.set("Calendar", forKey: "settings-assignments-reminder")
                    self.addToCalendar()
                }
                alertController.addAction(calendarAction)
                let reminderAction = UIAlertAction(title: NSLocalizedString("Reminders", comment:"Reminders app name"), style: .default) { (action) in
                    UserDefaults.standard.set("Reminders", forKey: "settings-assignments-reminder")
                    self.addToReminders()
                }
                alertController.addAction(reminderAction)
                self.present(alertController, animated: true)
            }
        }
    }

    func addToReminders() {
        if let _ = reminderAssignment {
            let eventStore : EKEventStore = EKEventStore()
            eventStore.requestAccess(to: .reminder) {
                granted, error in
                if (granted) && (error == nil) {
                    self.performSegue(withIdentifier: "Edit Reminder", sender: self)
                } else {
                    self.showPermissionNotGrantedAlert()
                }
            }
        }
    }
    
    func addToCalendar() {
        if let assignment = reminderAssignment {
            let eventStore : EKEventStore = EKEventStore()
            eventStore.requestAccess(to: .event, completion: {
                granted, error in
                if (granted) && (error == nil) {
                    
                    let event:EKEvent = EKEvent(eventStore: eventStore)
                    event.title = assignment.name
                    if let dueDate = assignment.dueDate {
                        event.startDate = dueDate
                        event.endDate = dueDate
                    }
                    event.notes = assignment.assignmentDescription
                    event.calendar = eventStore.defaultCalendarForNewEvents
                    event.location = assignment.courseName + "-" + assignment.courseSectionNumber
                    
                    let evc = EKEventEditViewController()
                    evc.event = event
                    evc.eventStore = eventStore
                    evc.editViewDelegate = self
                    self.reminderAssignment = nil
                    self.present(evc, animated: true, completion: nil)
                } else {
                    self.showPermissionNotGrantedAlert()
                }
            })
        }
    }
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        self.dismiss(animated: true, completion:nil)
    }
    
    private func showPermissionNotGrantedAlert() {
        
        let alertController = UIAlertController(title: NSLocalizedString("Permission not granted", comment: "Permission not granted title"), message: NSLocalizedString("You must give permission in Settings to allow access", comment: "Permission not granted message. Settings is the name of an app that is part of iOS. Apple translates this to be Arabic = الإعدادات Spanish/Portuguese=Ajustes French=Réglages"), preferredStyle: .alert)
        
        
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings application name. This is part of iOS.  Apple translates this to be Arabic = الإعدادات Spanish/Portuguese=Ajustes French=Réglages"), style: .default) { value in
            let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .default, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            () -> Void in
            self.present(alertController, animated: true, completion: nil)
            
        }
    }
}
