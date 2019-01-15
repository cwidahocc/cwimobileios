//
//  EventsViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/10/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class EventsViewController : UITableViewController, UISearchResultsUpdating , NSFetchedResultsControllerDelegate, EventsFilterDelegate, EllucianMobileLaunchableControllerProtocol {

    @IBOutlet var filterButton: UIBarButtonItem!
    
    let searchController = UISearchController(searchResultsController: nil)
    var module : Module!
    var eventModule : EventModule?
    var hiddenCategories = NSMutableSet()
    var searchString : String?
    
    let datetimeOutputFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
        
        }()
    let dateFormatterSectionHeader : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
        }()
    let timeFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    let dateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.module?.name
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = UITableViewAutomaticDimension
        buildSearchBar()
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            self.splitViewController?.preferredDisplayMode = .allVisible;
        } else {
            self.splitViewController?.preferredDisplayMode = .automatic;
        }
        
        // Recieve notification to ensure that EventsViewController searchController resets
        NotificationCenter.default.addObserver(self, selector: #selector(EventsViewController.detailViewWillAppear(_:)), name: EventsDetailViewController.eventsDetailNotification, object: nil)
        
        fetchEvents()
        reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendView("Events List", moduleName: self.module.name)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Make sure iPhone Plus behaves appropriately
        if UIScreen.main.traitCollection.userInterfaceIdiom != .pad {
            if self.splitViewController?.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular {
                self.searchController.isActive = false
                self.searchController.searchBar.setShowsCancelButton(false, animated: true)
            }
        }
    }
    
    @objc func detailViewWillAppear(_ notif: Notification) {
        self.searchController.isActive = false
        self.searchController.searchBar.setShowsCancelButton(false, animated: true)
    }
    
    // MARK: UISearchResultsUpdating delegate
    func updateSearchResults(for searchController: UISearchController) {
        self.sendEventToTracker1(category: .ui_Action, action: .search, label:"Search", moduleName:self.module!.name);
        _fetchedResultsController = nil
        self.tableView.reloadData()
    }
    
    // MARK: search
    func buildSearchBar() {
        self.searchController.searchResultsUpdater = self
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchController.searchBar
        
        self.definesPresentationContext = true
    }
    
    // MARK: data retrieval
    func fetchEvents() {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.module?.managedObjectContext
        privateContext.undoManager = nil
        
        let urlString = self.module?.property(forKey: "events")
        
        if self.fetchedResultsController.fetchedObjects!.count <= 0 {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
            hud.label.text = loadingString
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        }
        
        privateContext.perform { () -> Void in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            defer {
                DispatchQueue.main.async {
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            }
            
            do {
                let url = URL(string: urlString!)
                let responseData = try Data(contentsOf: url!, options:NSData.ReadingOptions())
                let json = JSON(data: responseData)
                
                var previousEvents = [Event]()
                var existingEvents = [Event]()
                var newKeys = [String]()
                
                let request = NSFetchRequest<Event>(entityName: "Event")
                if let name = self.module?.name {
                    request.predicate = NSPredicate(format:"module.name = %@", name)
                }
                let oldObjects = try privateContext.fetch(request)
                for oldObject in oldObjects {
                    previousEvents.append(oldObject)
                }
                
                let moduleRequest = NSFetchRequest<EventModule>(entityName: "EventModule")
                moduleRequest.predicate = NSPredicate(format: "name = %@", self.module!.name)
                let eventModules = try privateContext.fetch(moduleRequest)
                let eventModule : EventModule
                if eventModules.count > 0 {
                    eventModule = eventModules.last!
                } else {
                    eventModule = NSEntityDescription.insertNewObject(forEntityName: "EventModule", into: privateContext) as! EventModule
                    eventModule.name = self.module?.name
                    
                    
                }
                
                let categoryRequest = NSFetchRequest<EventCategory>(entityName: "EventCategory")
                categoryRequest.predicate = NSPredicate(format: "moduleName = %@", self.module!.name)
                let categoryArray = try privateContext.fetch(categoryRequest)
                var categoryMap = [String: EventCategory]()
                for eventCategory in categoryArray {
                    categoryMap[eventCategory.name] = eventCategory
                }
                
                var orderedKeys = [String]()
                for (key, _) in json {
                    orderedKeys.append(key)
                }
                orderedKeys.sort(){ $0 < $1 }
                
                for key in orderedKeys {
                    let eventsForDate = json[key]
                    for jsonEvent in eventsForDate.array! {
                        let uid = jsonEvent["uid"].string
                        
                        let filteredArray = previousEvents.filter({
                            let event = $0 as Event
                            return event.uid == uid;
                        })
                        if filteredArray.count > 0 {
                            existingEvents.append(filteredArray[0])
                        } else {
                            let event = NSEntityDescription.insertNewObject(forEntityName: "Event", into: privateContext) as! Event
                            event.module = eventModule
                            eventModule.addEventsObject(event)
                            event.uid = uid
                            newKeys.append(uid!)
                            if let contact = jsonEvent["title"].string , contact != "" {
                                event.contact = contact
                            }
                            let start = self.dateFormatter.date(from: jsonEvent["start"].string!)
                            let end = self.dateFormatter.date(from: jsonEvent["end"].string!)
                            
                            event.dateLabel = self.datetimeOutputFormatter.string(from: start!)
                            
                           if let description = jsonEvent["description"].string  {
                                event.description_ = description
                            }
                            event.endDate = end
                            if let location = jsonEvent["location"].string , location != "" {
                                event.location = location
                            }
                            event.startDate = start
                            if let summary = jsonEvent["summary"].string , summary != "" {
                                event.summary = summary
                            }
                            event.allDay = NSNumber(value: jsonEvent["allDay"].bool!)
                            let categories = jsonEvent["categories"].arrayValue.map {
                                return $0["name"].string
                            }

                            for categoryLabel in categories {
                                var category = categoryMap[categoryLabel!]
                                if category == nil {
                                    category = NSEntityDescription.insertNewObject(forEntityName: "EventCategory", into: privateContext) as? EventCategory
                                    category!.name = categoryLabel
                                    category!.moduleName = self.module?.name
                                    categoryMap[categoryLabel!] = category
                                }
                                event.addCategoryObject(category)
                                category!.addEventObject(event)
                            }
                        }
                    }
                }
            
                try privateContext.save()
                for oldObject in previousEvents {
                    if !existingEvents.contains(oldObject) {
                        privateContext.delete(oldObject)
                    }
                }
                try privateContext.save()
                
                privateContext.parent?.perform({
                    do {
                        try privateContext.save()
                    } catch let error {
                        print (error)
                    }
                })

                DispatchQueue.main.async {
                    self.readEventModule()
                    self.filterButton.isEnabled = true
                    
                }
                
            } catch let error {
                print (error)
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment:"title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment:"message when data cannot load due to a poor netwrok connection"), preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: UIAlertActionStyle.default)
                    alertController.addAction(alertAction)
                    self.present(alertController, animated: true)
                }
            }
        }
    }

    
    //MARK: segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Event Filter" {
            self.sendEvent(category: .ui_Action, action: .list_Select, label: "Select filter", moduleName: self.module?.name)
            let navigationController = segue.destination as! UINavigationController
            let detailController = navigationController.viewControllers[0] as! EventsFilterViewController
            detailController.eventModule = self.eventModule
            detailController.hiddenCategories = self.hiddenCategories
            detailController.module = self.module
            detailController.delegate = self
        } else if segue.identifier == "Show Detail" {
            let detailController = (segue.destination as! UINavigationController).topViewController as! EventsDetailViewController
            let event = fetchedResultsController.object(at: self.tableView.indexPathForSelectedRow!)
            detailController.event = event
            detailController.module = self.module
        }
    }
    
    //MARK reaad
    func readEventModule() {
        let request = NSFetchRequest<EventModule>(entityName: "EventModule")
        request.predicate = NSPredicate(format: "name = %@", self.module!.name)
        request.fetchLimit = 1
        do {
            let results = try self.module!.managedObjectContext!.fetch(request)
            if results.count > 0 {
                self.eventModule = results[0]
                let hiddenCategories = self.eventModule?.hiddenCategories
                if let hiddenCategories = hiddenCategories {
                    let array = hiddenCategories.components(separatedBy: ",")
                    self.hiddenCategories = NSMutableSet(array: array)
                    
                } else {
                    self.hiddenCategories = NSMutableSet()
                }
            } else {
                self.hiddenCategories = NSMutableSet()
                
            }
        } catch {}
    }
    
    //MARK: EventFilterDelegate
    func reloadData() {
        self.readEventModule()
        _fetchedResultsController = nil
        do {
            try self.fetchedResultsController.performFetch()
        } catch { }
        self.tableView.reloadData()
    }
    
    // MARK: fetch
    var fetchedResultsController: NSFetchedResultsController<Event> {
        // return if already initialized
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
        
        let request = NSFetchRequest<Event>(entityName: "Event")
        
        var subPredicates = [NSPredicate]()
        
        subPredicates.append( NSPredicate(format: "module.name = %@", self.module!.name) )
        
        if let searchString = self.searchController.searchBar.text , !searchString.isEmpty {
            subPredicates.append( NSPredicate(format: "((summary CONTAINS[cd] %@) OR (description_ CONTAINS[cd] %@) OR (location CONTAINS[cd] %@))", searchString, searchString, searchString) )
        }
        
        if self.hiddenCategories.count > 0 {
            subPredicates.append( NSPredicate(format: "NONE category.name IN %@",  self.hiddenCategories) )
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
        
        request.sortDescriptors = [NSSortDescriptor(key: "dateLabel", ascending: true),NSSortDescriptor(key: "startDate", ascending: true),NSSortDescriptor(key: "summary", ascending: true)]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "dateLabel", cacheName: nil)
        aFetchedResultsController.delegate = self
        self._fetchedResultsController = aFetchedResultsController
        
        do {
            try self._fetchedResultsController!.performFetch()
            
        } catch let error {
            print("fetch error: \(error)")
        }
        
        return self._fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<Event>?
    
    //MARK :UITable
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (fetchedResultsController.sections?.count)!
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
        let label = UILabel(frame: CGRect(x: 8,y: 0,width: tableView.frame.width, height: 30))
        label.translatesAutoresizingMaskIntoConstraints = false
        
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as NSFetchedResultsSectionInfo
            let header = currentSection.name
            let date = datetimeOutputFormatter.date(from: header)
            label.text = dateFormatterSectionHeader.string(from: date!)
        }
        
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as NSFetchedResultsSectionInfo
            return currentSection.numberOfObjects
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let event = fetchedResultsController.object(at: indexPath)
    
        let cell : UITableViewCell  = tableView.dequeueReusableCell(withIdentifier: "Event Cell", for: indexPath) as UITableViewCell

        let summaryLabel = cell.viewWithTag(1) as! UILabel
        let dateLabel = cell.viewWithTag(2) as! UILabel
        let categoryLabel = cell.viewWithTag(3) as! UILabel
        let locationLabel = cell.viewWithTag(4) as! UILabel
        let descriptionLabel = cell.viewWithTag(5) as! UILabel

        summaryLabel.text = event.summary
        
        if event.allDay.boolValue == true {
            dateLabel.text = NSLocalizedString("All Day", comment: "label for all day event")
        } else {
            if let startDate = event.startDate, let endDate = event.endDate {
                let formattedStart = self.timeFormatter.string(from: startDate)
                let formattedEnd = self.timeFormatter.string(from: endDate)
                dateLabel.text = String(format: NSLocalizedString("%@ - %@", comment: "event start - end"), formattedStart, formattedEnd)
            } else {
                dateLabel.text = self.timeFormatter.string(from: event.startDate)
            }
        }
        let categoriesArray = event.category.map{ m -> String in
            let category = m as! EventCategory
            return category.name
        }
        let categories = categoriesArray.joined(separator: ", ")
        
        categoryLabel.text = categories
        locationLabel.text = event.location
        if let description = event.description_ {
            descriptionLabel.text = description.convertingHTMLToPlainText()
        } else {
            descriptionLabel.text = ""
        }
        
        cell.layoutIfNeeded()
        
        return cell
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type{
        case NSFetchedResultsChangeType.insert:
            self.tableView.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.top)
            break
        case NSFetchedResultsChangeType.delete:
            self.tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.left)
            break
        case NSFetchedResultsChangeType.update:
            self.tableView.cellForRow(at: indexPath!)?.setNeedsLayout()
            break
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case NSFetchedResultsChangeType.insert:
            self.tableView.insertSections(indexSet, with: UITableViewRowAnimation.fade)
        case NSFetchedResultsChangeType.delete:
            self.tableView.deleteSections(indexSet, with: UITableViewRowAnimation.fade)
        case NSFetchedResultsChangeType.update:
            break
        case NSFetchedResultsChangeType.move:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
}
