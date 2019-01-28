//
//  AllEventsViewController.swift
//  Mobile
//
//  Created by Alan McEwan on 2/3/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation


class AllEventsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISplitViewControllerDelegate, EllucianMobileLaunchableControllerProtocol, MasterWithDetailSelectionDelegateProtocol, ILPAllItemsViewControllerProtocol
{
  
    @IBOutlet var allEventsTableView: UITableView!
    @IBOutlet weak var myTabBarItem: UITabBarItem!
    
    var detailSelectionDelegate: DetailSelectionDelegate!
    var allEventController: NSFetchedResultsController<CourseEvent>!
    var myDatetimeOutputFormatter: DateFormatter?
    var myManagedObjectContext: NSManagedObjectContext!
    var myTabBarController: UITabBarController!
    var showHeaders: Bool = true
    var module: Module!
    var detailViewController: CourseEventsDetailViewController!
    var selectedEvent:CourseEvent?
    
    
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
        
        allEventController = getEventsFetchedResultsController(true)
        do {
            try allEventController.performFetch()
        } catch let eventError as NSError {
             print("Unresolved error: fetch error: \(eventError.localizedDescription)")
        }
    
    allEventsTableView.register(NSClassFromString("UITableViewHeaderFooterView"), forHeaderFooterViewReuseIdentifier: "Header")
        self.view.backgroundColor = UIColor.primary
        
        let tabBarItem1 = myTabBarController?.tabBar.items?[1]
        if let tabBarItem1 = tabBarItem1 {
            tabBarItem1.selectedImage = UIImage(named: "ilp-events-selected")
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if selectedEvent == nil {
                if allEventController.fetchedObjects!.count > 0 {
                    let indexPath = IndexPath(row: 0, section: 0)
                    allEventsTableView.selectRow(at: indexPath, animated: true, scrollPosition:UITableViewScrollPosition.top)
                    tableView(allEventsTableView, didSelectRowAt: indexPath);
                }
            }
        }
        
        self.sendEventToTracker1(category: .ui_Action, action: .search, label:"ILP Events List", moduleName: "ILP");
    }
    
    /* called first
    begins update to `UITableView`
    ensures all updates are animated simultaneously */
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        allEventsTableView.beginUpdates()
    }
    
    /* helper method to configure a `UITableViewCell`
    ask `NSFetchedResultsController` for the model */
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let event = allEventController.object(at: indexPath)
        
        let nameLabel = cell.viewWithTag(100) as! UILabel
        nameLabel.text = event.title
        
        let courseNameLabel = cell.viewWithTag(101) as! UILabel
        courseNameLabel.text = event.courseName + "-" + event.courseSectionNumber
        
        let startDateLabel = cell.viewWithTag(102) as! UILabel
        
        if let date = event.startDate {
            startDateLabel.text = self.datetimeOutputFormatter()!.string(from: date)
        } else {
            startDateLabel.text = ""
        }
    }
    
    /* called:
    - when a new model is created
    - when an existing model is updated
    - when an existing model is deleted */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            
            switch type {
            case .insert:
                allEventsTableView.insertRows(at: [newIndexPath!], with: .fade)
            case .update:
                let cell = self.allEventsTableView.cellForRow(at: indexPath!)
                configureCell(cell!, atIndexPath: indexPath!)
                allEventsTableView.reloadRows(at: [indexPath!], with: .fade)
            case .delete:
                allEventsTableView.deleteRows(at: [indexPath!], with: .fade)
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
            allEventsTableView.insertSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
        case .delete:
            allEventsTableView.deleteSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
            
        default:
            break
        }
    }
    
    /* called last
    tells `UITableView` updates are complete */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        allEventsTableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let event = allEventController.object(at: indexPath)
        selectedEvent = event
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            detailViewController.courseName = event.courseName
            detailViewController.courseSectionNumber = event.courseSectionNumber
            detailViewController.eventTitle = event.title
            detailViewController.eventDescription = event.eventDescription
            detailViewController.location = event.location
            if let eventStartDate = event.startDate {
                detailViewController.startDate = eventStartDate
            }
            else {
                detailViewController.startDate = nil
            }
            if let eventEndDate = event.endDate {
                detailViewController.endDate = eventEndDate
            }
            else {
                detailViewController.endDate = nil
            }
            self.detailSelectionDelegate = detailViewController
            self.detailSelectionDelegate.selectedDetail(event, withIndex: indexPath, with: self.module!, withController: self)
            
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            self.performSegue(withIdentifier: "Show ILP Event Detail", sender:tableView)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Daily Event Cell", for: indexPath) as UITableViewCell
        cell.accessibilityTraits = UIAccessibilityTraitButton
        configureCell(cell, atIndexPath:indexPath)
        return cell

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        let count = allEventController.sections?.count
        
        if count == 0 || !showHeaders {
            return 0.0
        } else {
            return 18.0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let numberOfSections = allEventController.sections?.count
        return numberOfSections!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRowsInSection = allEventController.sections?[section].numberOfObjects
        return numberOfRowsInSection!
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if self.showHeaders {
            let h = allEventsTableView.dequeueReusableHeaderFooterView(withIdentifier: "Header")
            if let h = h {
                for subView in h.contentView.subviews
                {
                    if (subView.tag == 1 || subView.tag == 2)
                    {
                        subView.removeFromSuperview()
                    }
                }
                
                let sections = allEventController.sections
                
                let dateLabel:String? = sections?[section].name
                
                if h.backgroundColor != UIColor.accent {
                    h.contentView.backgroundColor = UIColor.accent
                    let headerLabel = UILabel()
                    headerLabel.tag = 1
                    headerLabel.text = dateLabel
                    headerLabel.backgroundColor = UIColor.clear
                    headerLabel.textColor = UIColor.subheaderText
                    headerLabel.font = UIFont.boldSystemFont(ofSize: 16)
                    headerLabel.minimumScaleFactor = 0.5
                    h.contentView.addSubview(headerLabel)
                    headerLabel.translatesAutoresizingMaskIntoConstraints = false
                    h.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[headerLabel]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["headerLabel":headerLabel]))
                    h.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[headerLabel]|", options: NSLayoutFormatOptions(rawValue: 0), metrics:nil, views: ["headerLabel":headerLabel]))
                    
                }
            }
            return h
            
        } else {
            return nil
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let indexPath: IndexPath! = allEventsTableView.indexPathForSelectedRow
        let event = allEventController.object(at: indexPath)
        let detailController = segue.destination as! CourseEventsDetailViewController
        detailController.eventTitle = event.title
        detailController.eventDescription = event.eventDescription
        detailController.location = event.location
        detailController.courseName = event.courseName
        detailController.courseSectionNumber = event.courseSectionNumber
        if let eventStartDate = event.startDate {
            detailController.startDate = eventStartDate
        }
        else {
            detailController.startDate = nil
        }
        if let eventEndDate = event.endDate {
            detailController.endDate = eventEndDate
        }
        else {
            detailController.endDate = nil
        }
        
        allEventsTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func eventFetchRequest() -> NSFetchRequest<CourseEvent> {
        
        var cal = Calendar.current
        let timezone = TimeZone.current
        cal.timeZone = timezone
        var beginComps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        beginComps.hour = 0
        beginComps.minute = 0
        beginComps.second = 0
        let beginOfToday = cal.date(from: beginComps)!
        
        let fetchRequest = NSFetchRequest<CourseEvent>(entityName: "CourseEvent")
        
        let predicate = NSPredicate(format: "(endDate >= %@)", argumentArray: [beginOfToday])
        
        let sortDescriptor = NSSortDescriptor(key:"startDate", ascending:true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        return fetchRequest
    }
    
    func getEventsFetchedResultsController(_ showOnlyItemsWithDates:Bool) -> NSFetchedResultsController<CourseEvent> {
        
        showHeaders = showOnlyItemsWithDates
        let importContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        importContext.parent = self.myManagedObjectContext
        
        let fetchRequest = eventFetchRequest()
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: "CourseEvent", in:importContext)
        fetchRequest.entity = entity;
        
        var theFetchedResultsController:NSFetchedResultsController<CourseEvent>!
        
        if showOnlyItemsWithDates {
            theFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:importContext, sectionNameKeyPath:"displayDateSectionHeader", cacheName:nil)
        } else {
            theFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:importContext, sectionNameKeyPath:nil, cacheName:nil)
        }

        return theFetchedResultsController!
    }

    
    func datetimeOutputFormatter() ->DateFormatter? {
        
        if (myDatetimeOutputFormatter == nil) {
            myDatetimeOutputFormatter = DateFormatter()
            myDatetimeOutputFormatter!.timeStyle = .short
            myDatetimeOutputFormatter!.dateStyle = .short
        }
        return myDatetimeOutputFormatter
    }
    
    func splitViewController(_ svc: UISplitViewController,
        shouldHide vc: UIViewController,
        in orientation: UIInterfaceOrientation) -> Bool {
            return false;
    }
    
    func setSelectedItem(_ item:CourseEvent?)
    {
        selectedEvent = item
    }
    
    func findSelectedItem() {
        
        if selectedEvent != nil {
            var indexPath = IndexPath(row: 0, section: 0)
            let myTargetItem = selectedEvent!
            if ( myTargetItem.managedObjectContext != nil)
            {
                for iter in allEventController.fetchedObjects!
                {
                    let tempEvent: CourseEvent = iter
                    if tempEvent.title == myTargetItem.title && tempEvent.startDate == myTargetItem.startDate && tempEvent.endDate==myTargetItem.endDate && tempEvent.eventDescription == myTargetItem.eventDescription {
                        indexPath = allEventController.indexPath(forObject: tempEvent)!
                    }
                }
                allEventsTableView.selectRow(at: indexPath, animated: true, scrollPosition:UITableViewScrollPosition.top)
                tableView(self.allEventsTableView, didSelectRowAt: indexPath);
            }
        }
    }
}
