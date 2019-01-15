//
//  NotificationsTableViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/13/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class NotificationsTableViewController : UITableViewController, NSFetchedResultsControllerDelegate, EllucianMobileLaunchableControllerProtocol {

    var module : Module!
    var indexPathToReselect : IndexPath?
    var uuid : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let splitView = self.splitViewController as! NotificationsSplitViewController
        if let selectedId = splitView.uuid {
            self.uuid = selectedId
        }
        
        self.title = self.module?.name
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension

        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            self.splitViewController?.preferredDisplayMode = .allVisible;
        } else {
            self.splitViewController?.preferredDisplayMode = .automatic;
        }

        fetchNotifications()
        reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendView( "Notifications List", moduleName: self.module?.name)
    }
    
    // MARK: data retrieval
    func fetchNotifications() {
        if let urlBase = self.module!.property(forKey: "notifications"), let userid =  CurrentUser.sharedInstance.userid?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            let urlString = "\(urlBase)/\(userid)"
            NotificationsFetcher.fetchNotificationsFromURL(notificationsUrl: urlString, withManagedObjectContext: CoreDataManager.sharedInstance.managedObjectContext, showLocalNotification: false, fromView: self)
        }
    }
    
    //MARK: segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Detail" {
            self.sendEventToTracker1(category: .ui_Action, action: .list_Select, label:"Select Notification", moduleName:self.module?.name);
            let detailController = (segue.destination as! UINavigationController).topViewController as! NotificationsDetailViewController
            let notification = fetchedResultsController.object(at: self.tableView.indexPathForSelectedRow!)
            detailController.notification = notification
            detailController.module = self.module
        }
    }
    
    //MARK: FeedFilterDelegate
    func reloadData() {
        _fetchedResultsController = nil
        do {
            try self.fetchedResultsController.performFetch()
        } catch { }
        self.tableView.reloadData()
        
        showNotificationSelectedIfSet()
    }
    
    private func showNotificationSelectedIfSet() {
        if let selectedId = self.uuid {
            if let notifications = _fetchedResultsController?.fetchedObjects {
                for (index, notification) in notifications.enumerated() {
                    if notification.notificationId == selectedId {
                        self.uuid = nil
                        let indexPath = IndexPath(row: index, section: 0)
                        tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.bottom)
                        self.performSegue(withIdentifier: "Show Detail", sender: nil)
                        tableView.reloadRows( at: [ indexPath ], with: UITableViewRowAnimation.none )
                    }
                }
            }
        }
    }
    
    // MARK: fetch
    var fetchedResultsController: NSFetchedResultsController<EllucianNotification> {
        // return if already initialized
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
        
        let request = NSFetchRequest<EllucianNotification>(entityName: "Notification")
        
        request.sortDescriptors = [NSSortDescriptor(key: "sticky", ascending: false),NSSortDescriptor(key: "noticeDate", ascending: false),NSSortDescriptor(key: "title", ascending: true)]
        
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
    var _fetchedResultsController: NSFetchedResultsController<EllucianNotification>?
    
    //MARK :UITable
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as NSFetchedResultsSectionInfo
            return currentSection.numberOfObjects
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Notification Cell", for: indexPath) as UITableViewCell
        let notification = fetchedResultsController.object(at: indexPath)

        let textLabel = cell.viewWithTag(1) as! UILabel
        let barImageView = cell.viewWithTag(2) as! UIImageView
        
        textLabel.text = notification.title

        var stickyColor = UIColor.clear
        if notification.read != nil && notification.read!.boolValue == true {
            textLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        } else {
            textLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        }
        if notification.sticky != nil && notification.sticky!.boolValue {
            stickyColor = UIColor(red: 241/255.0, green: 90/255.0, blue: 36/255.0, alpha: 1.0)
        }
        
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        // Create a 1 by 1 pixel context
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        stickyColor.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        barImageView.image = image;

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
            tableView.reloadRows( at: [ indexPath! ], with: UITableViewRowAnimation.none )
            indexPathToReselect = indexPath
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
        if let indexPath = indexPathToReselect {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.bottom)
            indexPathToReselect = nil
        }
        
        showNotificationSelectedIfSet()
    }
    
    //MARK: edit
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let notification = fetchedResultsController.object(at: indexPath)
        return notification.sticky == nil || !notification.sticky!.boolValue
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            let notification = fetchedResultsController.object(at: indexPath)
            NotificationsFetcher.deleteNotification(notification: notification, module: self.module!)
        }
    }

}
