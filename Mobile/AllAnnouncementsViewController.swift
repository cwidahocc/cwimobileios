//
//  AllAnnouncementsViewController.swift
//  Mobile
//
//  Created by Alan McEwan on 2/3/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class AllAnnouncementsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISplitViewControllerDelegate, EllucianMobileLaunchableControllerProtocol, MasterWithDetailSelectionDelegateProtocol, ILPAllItemsViewControllerProtocol
{
    @IBOutlet var allAnnouncementsTableView: UITableView!
    @IBOutlet weak var myTabBarItem: UITabBarItem!
    
    var allAnnouncementController: NSFetchedResultsController<CourseAnnouncement>!
    var myDatetimeOutputFormatter: DateFormatter?
    var myManagedObjectContext: NSManagedObjectContext!
    var myTabBarController: UITabBarController!
    var showHeaders:Bool = true
    var detailSelectionDelegate: DetailSelectionDelegate!
    var module: Module!
    var selectedAnnouncement:CourseAnnouncement?
    var detailViewController: CourseAnnouncementDetailViewController!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.extendedLayoutIncludesOpaqueBars = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        allAnnouncementController = getAnnouncementsFetchedResultsController()
        
        do {
            try allAnnouncementController.performFetch()
        } catch let error as NSError {
            print("Unresolved error: fetch error: \(error.localizedDescription)")
        }

    allAnnouncementsTableView.register(NSClassFromString("UITableViewHeaderFooterView"), forHeaderFooterViewReuseIdentifier: "Header")
        self.view.backgroundColor = UIColor.primary
        
        if let tabBarItem2 = myTabBarController?.tabBar.items?[2] {        tabBarItem2.selectedImage = UIImage(named:"ilp-announcements-selected")
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if selectedAnnouncement == nil {
                if allAnnouncementController.fetchedObjects!.count > 0 {
                    let indexPath = IndexPath(row: 0, section: 0)
                    allAnnouncementsTableView.selectRow(at: indexPath, animated: true, scrollPosition:UITableViewScrollPosition.top)
                    tableView(allAnnouncementsTableView, didSelectRowAt: indexPath);
                }
            }
        }
        
        self.sendEventToTracker1(category: .ui_Action, action: .search, label:"ILP Announcements List", moduleName: "ILP");
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UIDevice.current.userInterfaceIdiom == .pad {
            findSelectedItem()
        }
    }
    
    /* called first
    begins update to `UITableView`
    ensures all updates are animated simultaneously */
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        allAnnouncementsTableView.beginUpdates()
    }
    
    /* helper method to configure a `UITableViewCell`
    ask `NSFetchedResultsController` for the model */
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let announcement = allAnnouncementController.object(at: indexPath)
        
        let nameLabel = cell.viewWithTag(100) as! UILabel
        nameLabel.text = announcement.title
        let sectionNameLabel = cell.viewWithTag(102) as! UILabel
        sectionNameLabel.text = announcement.courseName + "-" + announcement.courseSectionNumber
        
        let dateLabel = cell.viewWithTag(101) as! UILabel
        
        if let date = announcement.date {
            dateLabel.text = self.datetimeOutputFormatter()!.string(from: date)
        } else {
            dateLabel.text = ""
        }
    }
    
    /* called:
    - when a new model is created
    - when an existing model is updated
    - when an existing model is deleted */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {            
        switch type {
            case .insert:
                allAnnouncementsTableView.insertRows(at: [newIndexPath!], with: .fade)
            case .update:
                let cell = self.allAnnouncementsTableView.cellForRow(at: indexPath!)
                configureCell(cell!, atIndexPath: indexPath!)
                allAnnouncementsTableView.reloadRows(at: [indexPath!], with: .fade)
            case .delete:
                allAnnouncementsTableView.deleteRows(at: [indexPath!], with: .fade)
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
                allAnnouncementsTableView.insertSections(IndexSet(integer: sectionIndex), with: UITableViewRowAnimation.fade)
            case .delete:
                allAnnouncementsTableView.deleteSections(IndexSet(integer: sectionIndex), with: UITableViewRowAnimation.fade)
            default:
                break
        }
    }
    
    /* called last
    tells `UITableView` updates are complete */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        allAnnouncementsTableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let announcement = allAnnouncementController.object(at: indexPath)
        selectedAnnouncement = announcement
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            detailViewController.courseName = announcement.courseName
            detailViewController.courseSectionNumber = announcement.courseSectionNumber
            detailViewController.itemTitle = announcement.title
            detailViewController.itemContent = announcement.content
            detailViewController.itemLink = announcement.website
            if let announcementDate = announcement.date {
                detailViewController.itemPostDateTime = announcementDate
            }
            else {
                detailViewController.itemPostDateTime = nil
            }
            self.detailSelectionDelegate = detailViewController
            self.detailSelectionDelegate.selectedDetail(announcement, withIndex: indexPath, with: self.module!, withController: self)
            
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            self.performSegue(withIdentifier: "Show ILP Announcement Detail", sender:tableView)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if self.showHeaders {
            let h = allAnnouncementsTableView.dequeueReusableHeaderFooterView(withIdentifier: "Header")
            if let h = h {
                
                for subView in h.contentView.subviews
                {
                    if (subView.tag == 1 || subView.tag == 2)
                    {
                        subView.removeFromSuperview()
                    }
                }
                
                let sections = allAnnouncementController.sections
                
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Daily Announcement Cell", for: indexPath) as UITableViewCell
        cell.accessibilityTraits = UIAccessibilityTraitButton
        configureCell(cell, atIndexPath: indexPath)

        return cell
    }
    
    func tableView(_ tableView: UITableView,
        heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        let count = allAnnouncementController.sections?.count
        if count == 0 || !showHeaders {
            return 0.0
        } else {
            return 18.0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let numberOfSections = allAnnouncementController.sections?.count
        return numberOfSections!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRowsInSection = allAnnouncementController.sections?[section].numberOfObjects
        return numberOfRowsInSection!
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let indexPath: IndexPath! = allAnnouncementsTableView.indexPathForSelectedRow
        let announcement = allAnnouncementController.object(at: indexPath)
        let detailController = segue.destination as! CourseAnnouncementDetailViewController
        detailController.courseName = announcement.courseName
        detailController.courseSectionNumber = announcement.courseSectionNumber
        detailController.itemTitle = announcement.title
        detailController.itemContent = announcement.content
        detailController.itemLink = announcement.website.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if let announcementDate = announcement.date {
            detailController.itemPostDateTime = announcementDate
        }
        else {
            detailController.itemPostDateTime = nil
        }

        allAnnouncementsTableView.deselectRow(at: indexPath, animated:true)
    }
    
    
    func announcementFetchRequest() -> NSFetchRequest<CourseAnnouncement> {
        
        let fetchRequest = NSFetchRequest<CourseAnnouncement>(entityName: "CourseAnnouncement")
        let sortDescriptor = NSSortDescriptor(key:"date", ascending:false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        return fetchRequest
    }
    
    
    func getAnnouncementsFetchedResultsController() -> NSFetchedResultsController<CourseAnnouncement> {
        
        let importContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        importContext.parent = self.myManagedObjectContext
        
        let fetchRequest = announcementFetchRequest()
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: "CourseAnnouncement", in:importContext)
        fetchRequest.entity = entity;
        
        var theFetchedResultsController:NSFetchedResultsController<CourseAnnouncement>?
        
        
        theFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:importContext, sectionNameKeyPath:"displayDateSectionHeader", cacheName:nil)
        
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
    
    func setSelectedItem(_ item:CourseAnnouncement?)
    {
        selectedAnnouncement = item
    }
    
    func findSelectedItem() {
        if selectedAnnouncement != nil {
            var indexPath = IndexPath(row: 0, section: 0)
            let myTargetItem = selectedAnnouncement!
            
            for iter in allAnnouncementController.fetchedObjects!
            {
                let temp: CourseAnnouncement = iter
                if myTargetItem.website != nil && temp.website == myTargetItem.website {
                    indexPath = allAnnouncementController.indexPath(forObject: temp)!
                }
            }
            allAnnouncementsTableView.selectRow(at: indexPath, animated: true, scrollPosition:UITableViewScrollPosition.top)
            tableView(self.allAnnouncementsTableView, didSelectRowAt: indexPath);
        }
    }

}
