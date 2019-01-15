     //
//  SwiftDailyViewController.swift
//  Mobile
//
//  Created by Alan McEwan on 1/9/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import UIKit



class ILPViewController : UIViewController, UIGestureRecognizerDelegate, UISplitViewControllerDelegate, EllucianMobileLaunchableControllerProtocol
{

    @objc var requestedAssignmentId: String? = nil

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var assignmentsCardTitle: UILabel!
    @IBOutlet weak var showAllAssignmentsView: UIView!
    @IBOutlet weak var assignmentCardView: UIView!
    @IBOutlet var assignmentTableView: UITableView!
    
    @IBOutlet weak var eventsCardTitle: UILabel!
    @IBOutlet weak var showAllEventsView: UIView!
    @IBOutlet weak var eventCardView: UIView!
    @IBOutlet var eventTableView: UITableView!
    
    @IBOutlet weak var announcementsCardTitle: UILabel!
    @IBOutlet weak var showAllAnnouncementsView: UIView!
    @IBOutlet weak var announcementCardView: UIView!
    @IBOutlet var announcementTableView: UITableView!
    
    @IBOutlet weak var assignmentTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var assignmentTableWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var eventTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var eventTableWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var announcementTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var announcementTableWidthConstraint: NSLayoutConstraint!
    
    var cardInsetConstant:CGFloat = 0
    //Landscape Constraints
    var landscapeConstraintArray = [NSLayoutConstraint]()
    //Portrait Constraints
    var portraitConstraintArray = [NSLayoutConstraint]()
    
    var assignmentsFetchedResultController: NSFetchedResultsController<CourseAssignment>?
    var assignmentsTableViewDelegate: AssignmentTableViewDelegate?
    
    var eventsFetchedResultsController: NSFetchedResultsController<CourseEvent>?
    var eventsTableViewDelegate: EventTableViewDelegate?
    
    var announcementsFetchedResultsController : NSFetchedResultsController<CourseAnnouncement>?
    var announcementsTableViewDelegate: AnnouncementTableViewDelegate?
    
    var module: Module!
    
    var myDatetimeFormatter: DateFormatter?
    var darkGray:UIColor = UIColor(red: 152.0/255.0, green: 152.0/255.0, blue: 152.0/255.0, alpha: 1.0)
    
    var checkAllUpdated: Int!
    static let EventsUpdatedNotification = Notification.Name("EventsUpdatedNotification")
    static let AssignmentsUpdatedNotification = Notification.Name("AssignmentsUpdatedNotification")
    static let AnnouncementsUpdatedNotification = Notification.Name("AnnouncementsUpdatedNotification")
    
    override func viewWillAppear(_ animated: Bool) {
        resizeAfterOrientationChange()
        //reset the delegates on the fetched results controller
        assignmentsFetchedResultController!.delegate = assignmentsTableViewDelegate
        eventsFetchedResultsController!.delegate = eventsTableViewDelegate
        announcementsFetchedResultsController!.delegate = announcementsTableViewDelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showAllAnnouncementsView.isUserInteractionEnabled = true
        
        self.navigationController?.navigationBar.isTranslucent = false;
    
        self.title = self.module!.name;
        
        self.assignmentsCardTitle.accessibilityTraits = UIAccessibilityTraitButton
        self.eventsCardTitle.accessibilityTraits = UIAccessibilityTraitButton
        self.announcementsCardTitle.accessibilityTraits = UIAccessibilityTraitButton
        
        if let hudView = self.view {
            let hud = MBProgressHUD.showAdded(to: hudView, animated: true)
            let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
            hud.label.text = loadingString
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ILPViewController.dataFinishedLoading(_:)), name: ILPViewController.AnnouncementsUpdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ILPViewController.dataFinishedLoading(_:)), name: ILPViewController.AssignmentsUpdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ILPViewController.dataFinishedLoading(_:)), name: ILPViewController.EventsUpdatedNotification, object: nil)

        assignmentsFetchedResultController = getAssignmentsFetchedResultsController()
        assignmentsTableViewDelegate = AssignmentTableViewDelegate(tableView: assignmentTableView, resultsController: assignmentsFetchedResultController!, heightConstraint: assignmentTableHeightConstraint, widthConstraint: assignmentTableWidthConstraint, parentModule:self.module!, viewController:self)
        do {
            try assignmentsFetchedResultController!.performFetch()
        } catch let assignmentError as NSError {
            print("Unresolved error fetching assignments: fetch error: \(assignmentError.localizedDescription)")
        }
        
        announcementsFetchedResultsController = getAnnouncementsFetchedResultsController()
        announcementsTableViewDelegate = AnnouncementTableViewDelegate(tableView: announcementTableView, controller: announcementsFetchedResultsController!, heightConstraint:announcementTableHeightConstraint, widthConstraint: announcementTableWidthConstraint, parentModule:module!)
        do {
            try announcementsFetchedResultsController!.performFetch()
        } catch let announcementError as NSError {
            print("Unresolved error fetching announcements: fetch error: \(announcementError.localizedDescription)")
        }
        
        eventsFetchedResultsController = getEventsFetchedResultsController()
        eventsTableViewDelegate = EventTableViewDelegate(tableView: eventTableView, controller: eventsFetchedResultsController!, heightConstraint: eventTableHeightConstraint, widthConstraint: eventTableWidthConstraint, parentModule:module!)
        do {
            try eventsFetchedResultsController!.performFetch()
        } catch let eventError as NSError {
            print("Unresolved error fetching events: fetch error: \(eventError.localizedDescription)")
        }

        // Ensure that all information is updated before displaying assignment from widget
        checkAllUpdated = 0
        
        let currentUser = CurrentUser.sharedInstance
        
        if (currentUser.isLoggedIn) {
            fetchAnnouncements(self)
            fetchEvents(self)
            fetchAssignments(self)
        }
        
        var screenWidth = UIScreen.main.bounds.size.width
        if #available(iOS 11, *) {
            screenWidth = screenWidth - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right
            
        }
        if UIDevice.current.userInterfaceIdiom == .pad
        {
            cardInsetConstant = 25.0
            initIPadPortraitConstraints()
            initIPadLandscapeConstraints()

            switch UIDevice.current.orientation{
            case .portrait:
                scrollView.removeConstraints(landscapeConstraintArray)
                scrollView.addConstraints(portraitConstraintArray)
                assignmentTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                announcementTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                eventTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
            case .portraitUpsideDown:
                scrollView.removeConstraints(landscapeConstraintArray)
                scrollView.addConstraints(portraitConstraintArray)
                assignmentTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                announcementTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                eventTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
            case .landscapeLeft:
                scrollView.removeConstraints(portraitConstraintArray)
                scrollView.addConstraints(landscapeConstraintArray)
                assignmentTableWidthConstraint.constant = (screenWidth - 100)/3
                announcementTableWidthConstraint.constant = (screenWidth - 100)/3
                eventTableWidthConstraint.constant = (screenWidth - 100)/3
            case .landscapeRight:
                scrollView.removeConstraints(portraitConstraintArray)
                scrollView.addConstraints(landscapeConstraintArray)
                assignmentTableWidthConstraint.constant = (screenWidth - 100)/3
                announcementTableWidthConstraint.constant = (screenWidth - 100)/3
                eventTableWidthConstraint.constant = (screenWidth - 100)/3
            default:
                scrollView.removeConstraints(landscapeConstraintArray)
                scrollView.addConstraints(portraitConstraintArray)
                assignmentTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                announcementTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                eventTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
            }
        } else if UIDevice.current.userInterfaceIdiom == .phone
        {
            cardInsetConstant = 15.0
            assignmentTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
            announcementTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
            eventTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
        }
        
        NotificationCenter.default.addObserver(self, selector:#selector(ILPViewController.fetchAssignments(_:)), name:CurrentUser.LoginExecutorSuccessNotification, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(ILPViewController.fetchEvents(_:)), name: CurrentUser.LoginExecutorSuccessNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(ILPViewController.fetchAnnouncements(_:)), name: CurrentUser.LoginExecutorSuccessNotification, object: nil)
        
        var totalRowHeight:CGFloat = 0.0
        
        for section in assignmentsFetchedResultController!.sections! {
            if section.name  == NSLocalizedString("DUE TODAY", comment:"due today assignment indicator for ilp module") {
                totalRowHeight +=  CGFloat(section.numberOfObjects) * 40.0
            } else if section.name == NSLocalizedString("OVERDUE", comment:"overdue assignment indicator for ilp module") {
                totalRowHeight +=  CGFloat(section.numberOfObjects) * 50.0
            }
        }
        assignmentTableHeightConstraint.constant = totalRowHeight + (CGFloat(assignmentsFetchedResultController!.sections!.count) * 30.0) + 50.0
        
        eventTableHeightConstraint.constant = (CGFloat(eventsFetchedResultsController!.fetchedObjects!.count) * 50.0) + 50.0
        announcementTableHeightConstraint.constant = (CGFloat(announcementsFetchedResultsController!.fetchedObjects!.count) * 50.0) + 50.0
        
        assignmentTableView.register(NSClassFromString("UITableViewHeaderFooterView"), forHeaderFooterViewReuseIdentifier: "Header")
        eventTableView.register(NSClassFromString("UITableViewHeaderFooterView"), forHeaderFooterViewReuseIdentifier: "Header")
        announcementTableView.register(NSClassFromString("UITableViewHeaderFooterView"), forHeaderFooterViewReuseIdentifier: "Header")
        
        assignmentsCardTitle.text = NSLocalizedString("Assignments", comment:"ILP View: Assignments Card Title")
        announcementsCardTitle.text = NSLocalizedString("Announcements", comment:"ILP View: Announcements Card Title")
        eventsCardTitle.text = NSLocalizedString("Events", comment:"ILP View: Events Card Title")
        
        styleCardHeaders()
        
        self.sendEventToTracker1(category: .ui_Action, action: .search, label:"ILP Today Summary", moduleName:"ILP");
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resizeAfterOrientationChange()
        self.sendView( "ILP view", moduleName:self.module?.name)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        //remove the delegates on the fetched results controller so that other controllers accessing the objects don't execute the respective delegates
        assignmentsFetchedResultController!.delegate = nil
        eventsFetchedResultsController!.delegate = nil
        announcementsFetchedResultsController!.delegate = nil
    }
    
    func assignmentFetchRequest() -> NSFetchRequest<CourseAssignment> {
        
        let todayDateRange = createTodayDateRange() as NSArray?
        let endOfToday = todayDateRange![1] as! Date
        
        ////today only
        ////let predicate = NSPredicate(format: "(dueDate >= %@) AND (dueDate <= %@)", argumentArray: todayDateRange)
        
        //today and earlier
        let predicate = NSPredicate(format: "(dueDate <= %@)", argumentArray: [endOfToday])
        
        ////debug toggle to simulate no data scenario
        ////let predicate = NSPredicate(format: "(dueDate < %@) AND (dueDate > %@)", argumentArray: todayDateRange)
        
        let fetchRequest = NSFetchRequest<CourseAssignment>(entityName: "CourseAssignment")
        let sortDescriptor = NSSortDescriptor(key:"dueDate", ascending:true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        return fetchRequest
    }
    
    func getAssignmentsFetchedResultsController() -> NSFetchedResultsController<CourseAssignment> {

        let fetchRequest = assignmentFetchRequest()
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: "CourseAssignment", in:self.module!.managedObjectContext!)
        fetchRequest.entity = entity;
        let theFetchedResultsController:NSFetchedResultsController? = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:self.module!.managedObjectContext!, sectionNameKeyPath:"overDueWarningSectionHeader", cacheName:"ilp")
    
        return theFetchedResultsController!
        
    }
    
    
    @objc func fetchAssignments(_ sender:AnyObject) {
        
        let importContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        importContext.parent = self.module?.managedObjectContext
        
        let urlString = NSString( format:"%@/%@/assignments", self.module!.property(forKey: "ilp")!, CurrentUser.sharedInstance.userid! )
        let url: URL? = URL(string: urlString as String)
        
        importContext.perform( {
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            let authenticatedRequest = AuthenticatedRequest()
            let responseData = authenticatedRequest.requestURL(url, fromView: self)
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if let response = responseData {
                NotificationCenter.default.removeObserver(self, name:CurrentUser.LoginExecutorSuccessNotification, object:nil)
                
                let json = JSON(data: response)
                
                let request = NSFetchRequest<CourseAssignment>(entityName: "CourseAssignment")

                var oldObjects: [AnyObject]?
                do {
                    oldObjects = try importContext.fetch(request)
                } catch {
                }
                
                for oldObject in oldObjects! {
                    importContext.delete(oldObject as! NSManagedObject)
                }

                let assignmentList: Array<JSON> = json["assignments"].arrayValue
                
                for  jsonDictionary in assignmentList {
                    let entry:CourseAssignment = NSEntityDescription.insertNewObject(forEntityName: "CourseAssignment", into: importContext) as! CourseAssignment
                    entry.sectionId = jsonDictionary["sectionId"].stringValue
                    entry.courseName = jsonDictionary["courseName"].stringValue
                    entry.courseSectionNumber = jsonDictionary["courseSectionNumber"].stringValue
                    entry.name = jsonDictionary["name"].stringValue
                    entry.assignmentDescription = jsonDictionary["description"].stringValue
                    entry.dueDate = self.datetimeFormatter()?.date(from: jsonDictionary["dueDate"].stringValue)
                    entry.url = jsonDictionary["url"].stringValue
                }
                
                do {
                    try importContext.save()
                } catch let saveError as NSError {
                    print("save error: \(saveError.localizedDescription)")
                } catch {
                }
            } else {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment:"title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment:"message when data cannot load due to a poor netwrok connection"), preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: UIAlertActionStyle.default)
                    alertController.addAction(alertAction)
                    self.present(alertController, animated: true)
                }
            }
            importContext.parent?.perform({
                do {
                    try importContext.parent!.save()
                } catch let parentError as NSError {
                    print("Could not save to store after update to course assignments: \(parentError.localizedDescription)")
                } catch {
                    
                }
            })
            NotificationCenter.default.post(name: ILPViewController.AssignmentsUpdatedNotification, object: nil)
        })
    }

    func announcementFetchRequest() -> NSFetchRequest<CourseAnnouncement> {
        
        let todayDateRange = createTodayDateRange()
        
        //debug toggle to simulate no data scenario
        //let predicate = NSPredicate(format: "(date < %@) AND (date > %@)", argumentArray: todayDateRange)
        let predicate = NSPredicate(format: "(date >= %@) AND (date <= %@)", argumentArray: todayDateRange)
        
        let fetchRequest = NSFetchRequest<CourseAnnouncement>(entityName: "CourseAnnouncement")

        let sortDescriptor = NSSortDescriptor(key:"date", ascending:false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        return fetchRequest
    }
    
    
    func getAnnouncementsFetchedResultsController() -> NSFetchedResultsController<CourseAnnouncement> {
        let fetchRequest = announcementFetchRequest()
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: "CourseAnnouncement", in:self.module!.managedObjectContext!)
        fetchRequest.entity = entity;
        
        let theFetchedResultsController:NSFetchedResultsController? = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:(module?.managedObjectContext!)!, sectionNameKeyPath:nil, cacheName:"ilp")
        return theFetchedResultsController!
        
    }
    
    @objc func fetchAnnouncements(_ sender:AnyObject) {
        let importContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        importContext.parent = self.module?.managedObjectContext
        
        let urlString = NSString( format:"%@/%@/announcements", self.module!.property(forKey: "ilp")!, CurrentUser.sharedInstance.userid! )
        let url: URL? = URL(string: urlString as String)

        importContext.perform( {
        
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            let authenticatedRequest = AuthenticatedRequest()
            let responseData = authenticatedRequest.requestURL(url, fromView: self)
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if let response = responseData {
                
                NotificationCenter.default.removeObserver(self, name:CurrentUser.LoginExecutorSuccessNotification, object:nil)
                
                let json = JSON(data: response)
                
                let request = NSFetchRequest<CourseAnnouncement>(entityName: "CourseAnnouncement")

                var oldObjects: [AnyObject]?
                do {
                    oldObjects = try importContext.fetch(request)
                } catch {
                }
                
                for oldObject in oldObjects! {
                    importContext.delete(oldObject as! NSManagedObject)
                }
                
                let announcementList: Array<JSON> = json["items"].arrayValue
                
                for  jsonDictionary in announcementList {
                    let entry:CourseAnnouncement = NSEntityDescription.insertNewObject(forEntityName: "CourseAnnouncement", into: importContext) as! CourseAnnouncement
                    
                    entry.sectionId = jsonDictionary["sectionId"].stringValue
                    entry.courseName = jsonDictionary["courseName"].stringValue
                    entry.courseSectionNumber = jsonDictionary["courseSectionNumber"].stringValue
                    entry.title = jsonDictionary["title"].stringValue
                    entry.content = jsonDictionary["content"].stringValue
                    if let entryDate = self.datetimeFormatter()?.date(from: jsonDictionary["date"].stringValue) {
                        entry.date = entryDate
                    } else {
                        
                        let date = Date()
                        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
                        let components = cal.dateComponents([.day, .month, .year], from: date)
                        let todayAtMidnight = cal.date(from: components)

                        entry.date = todayAtMidnight
                    }
                    
                    entry.website = jsonDictionary["website"].stringValue
                }
                

                do {
                    try importContext.save()
                } catch let error as NSError {
                    print("save error: \(error.localizedDescription)")
                } catch {
                }
            } else {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment:"title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment:"message when data cannot load due to a poor netwrok connection"), preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: UIAlertActionStyle.default)
                    alertController.addAction(alertAction)
                    self.present(alertController, animated: true)
                }
            }
            importContext.parent?.perform({
                do {
                    try importContext.parent!.save()
                } catch let parentError as NSError {
                    print("Could not save to store after update to course announcements: \(parentError.localizedDescription)")
                } catch {
                }
            })
            NotificationCenter.default.post(name: ILPViewController.AnnouncementsUpdatedNotification, object: nil)
        })
    }
    
    func createTodayDateRange() -> [Date] {
        var cal = Calendar.current
        let timezone = TimeZone.current
        cal.timeZone = timezone
        
        var beginComps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        beginComps.hour = 0
        beginComps.minute = 0
        beginComps.second = 0
        
        var endComps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        endComps.hour = 23
        endComps.minute = 59
        endComps.second = 59
        
        let beginOfToday = cal.date(from: beginComps)!
        let endOfToday = cal.date(from: endComps)!
        
        return [beginOfToday, endOfToday, beginOfToday, endOfToday, beginOfToday, endOfToday]
    }
    
    func eventFetchRequest() -> NSFetchRequest<CourseEvent> {
        
        let todayDateRange = createTodayDateRange()
        
        let predicate = NSPredicate(format: "((startDate >= %@) AND (startDate <= %@)) OR ((endDate >= %@) AND (endDate <= %@)) OR ((startDate <= %@) AND (endDate >= %@))", argumentArray: todayDateRange)
        //debug toggle to simulate no data scenario
        //let predicate = NSPredicate(format: "(startDate < %@) AND (startDate > %@)", argumentArray: todayDateRange)
        
        let fetchRequest = NSFetchRequest<CourseEvent>(entityName: "CourseEvent")
        let sortDescriptor = NSSortDescriptor(key:"startDate", ascending:true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        return fetchRequest
    }
    
    func getEventsFetchedResultsController() -> NSFetchedResultsController<CourseEvent> {
        
        let fetchRequest = eventFetchRequest()
        let entity:NSEntityDescription? = NSEntityDescription.entity(forEntityName: "CourseEvent", in:self.module!.managedObjectContext!)
        fetchRequest.entity = entity;
        let theFetchedResultsController:NSFetchedResultsController? = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:module!.managedObjectContext!, sectionNameKeyPath:nil, cacheName:"ilp")
        return theFetchedResultsController!
    }
    
    
    @objc func fetchEvents(_ sender:AnyObject) {
        let importContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        importContext.parent = self.module?.managedObjectContext
        
        let urlString = NSString( format:"%@/%@/events", self.module!.property(forKey: "ilp")!, CurrentUser.sharedInstance.userid! )
        let url: URL? = URL(string: urlString as String)
        
        importContext.perform( {

            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            let authenticatedRequest = AuthenticatedRequest()
            let responseData = authenticatedRequest.requestURL(url, fromView: self)
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if let response = responseData {
                
                NotificationCenter.default.removeObserver(self, name:CurrentUser.LoginExecutorSuccessNotification, object:nil)
                
                let json = JSON(data: response)
                
                let request = NSFetchRequest<CourseEvent>(entityName: "CourseEvent")
                var oldObjects: [AnyObject]?
                do {
                    oldObjects = try importContext.fetch(request)
                } catch {
                }
                
                for oldObject in oldObjects! {
                    importContext.delete(oldObject as! NSManagedObject)
                }
                
                let assignmentList: Array<JSON> = json["events"].arrayValue
                
                for  jsonDictionary in assignmentList {
                    let entry:CourseEvent = NSEntityDescription.insertNewObject(forEntityName: "CourseEvent", into: importContext) as! CourseEvent
                    
                    entry.sectionId = jsonDictionary["sectionId"].stringValue
                    entry.courseName = jsonDictionary["courseName"].stringValue
                    entry.courseSectionNumber = jsonDictionary["courseSectionNumber"].stringValue
                    entry.title = jsonDictionary["title"].stringValue
                    entry.eventDescription = jsonDictionary["description"].stringValue
                    entry.startDate = self.datetimeFormatter()?.date(from: jsonDictionary["startDate"].stringValue)
                    entry.endDate = self.datetimeFormatter()?.date(from: jsonDictionary["endDate"].stringValue)
                    entry.location = jsonDictionary["location"].stringValue
                }
                
                do {
                    try importContext.save()
                } catch let error as NSError {
                    print("save error: \(error.localizedDescription)")
                } catch {
                    
                }
            } else {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment:"title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment:"message when data cannot load due to a poor netwrok connection"), preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: UIAlertActionStyle.default)
                    alertController.addAction(alertAction)
                    self.present(alertController, animated: true)
                }
            }
            importContext.parent?.perform({
                do {
                    try importContext.parent!.save()
                } catch let error as NSError {
                    print("Could not save to store after update to course events: \(error.localizedDescription)")
                } catch {
                    
                }
            })
            NotificationCenter.default.post(name: ILPViewController.EventsUpdatedNotification, object: nil)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {

        if (segue.identifier == "Show ILP Assignment Detail") {

            if(requestedAssignmentId != nil) {
                let indexPath = indexPathForAssignmentWithUrl(requestedAssignmentId)
                
                if let indexPath = indexPath {
                    assignmentTableView.selectRow(at: indexPath, animated: true, scrollPosition:UITableViewScrollPosition.top)
                }
            }
            let indexPath: IndexPath! = assignmentTableView.indexPathForSelectedRow
            let assignment = assignmentsFetchedResultController!.object(at: indexPath)
            let detailController = segue.destination as! CourseAssignmentDetailViewController
            detailController.courseName = assignment.courseName
            detailController.courseSectionNumber = assignment.courseSectionNumber
            detailController.itemTitle = assignment.name
            detailController.itemContent = assignment.assignmentDescription
            if let url = assignment.url {
                    detailController.itemLink = url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            if let assignmentDate = assignment.dueDate {
                detailController.itemPostDateTime = assignmentDate
            }
            else {
                detailController.itemPostDateTime = nil
            }
            detailController.module = module;
            assignmentTableView.deselectRow(at: indexPath, animated:true)
            requestedAssignmentId = nil
        
        }
        else if (segue.identifier == "Show ILP Announcement Detail") {
            let indexPath: IndexPath! = announcementTableView.indexPathForSelectedRow
            let announcement = announcementsFetchedResultsController!.object(at: indexPath)
            let detailController = segue.destination as! CourseAnnouncementDetailViewController
            detailController.courseName = announcement.courseName
            detailController.courseSectionNumber = announcement.courseSectionNumber
            detailController.itemTitle = announcement.title
            detailController.itemContent = announcement.content
            if let url = announcement.website {
                detailController.itemLink = url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            if let announcementDate = announcement.date {
                detailController.itemPostDateTime = announcementDate
            }
            else {
                detailController.itemPostDateTime = nil
            }
            
            detailController.module = module;
            announcementTableView.deselectRow(at: indexPath, animated:true)
            self.sendEventToTracker1(category: .ui_Action, action: .search, label:"Show ILP Announcement Detail", moduleName:"ILP");
        }
        else if (segue.identifier == "Show ILP Event Detail") {
            let indexPath: IndexPath! = eventTableView.indexPathForSelectedRow
            let event = eventsFetchedResultsController!.object(at: indexPath) 
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
            
            detailController.module = module;
            eventTableView.deselectRow(at: indexPath, animated: true)
        }
        else if (segue.identifier == "Show All ILP Assignments") {
            let tabBarController = segue.destination as! UITabBarController
            
            self.initManagedObjectContextInDetailViewControllers(tabBarController)
            tabBarController.selectedIndex = 0

        }
        else if (segue.identifier == "Show All ILP Events") {
            let tabBarController = segue.destination as! UITabBarController
            self.initManagedObjectContextInDetailViewControllers(tabBarController)
            tabBarController.selectedIndex = 1

        }
        else if (segue.identifier == "Show All ILP Announcements") {
            let tabBarController = segue.destination as! UITabBarController
            self.initManagedObjectContextInDetailViewControllers(tabBarController)
            tabBarController.selectedIndex = 2

        }
        else if (segue.identifier == "Show ILP Assignment Split View For Assignment")
        {
            if(requestedAssignmentId != nil) {
                let indexPath = indexPathForAssignmentWithUrl(requestedAssignmentId)
                
                if let indexPath = indexPath {
                    assignmentTableView.selectRow(at: indexPath, animated: true, scrollPosition:UITableViewScrollPosition.top)
                }
            }
            let indexPath: IndexPath! = assignmentTableView.indexPathForSelectedRow
            let assignment = assignmentsFetchedResultController!.object(at: indexPath)
            let tabBarController = segue.destination as! UITabBarController
            self.initManagedObjectContextInSplitViewControllers(tabBarController, selectedItem:assignment)
            tabBarController.selectedIndex = 0
            assignmentTableView.deselectRow(at: indexPath, animated:true)
            requestedAssignmentId = nil
        }
        else if (segue.identifier == "Show ILP Event Split View For Event" )
        {
            let indexPath: IndexPath! = eventTableView.indexPathForSelectedRow
            let event = eventsFetchedResultsController!.object(at: indexPath)
            let tabBarController = segue.destination as! UITabBarController
            self.initManagedObjectContextInSplitViewControllers(tabBarController, selectedItem:event)
            tabBarController.selectedIndex = 1
            
            eventTableView.deselectRow(at: indexPath, animated: true)
        }
        else if (segue.identifier == "Show ILP Announcement Split View For Announcement")
        {
            let indexPath: IndexPath! = announcementTableView.indexPathForSelectedRow
            let announcement = announcementsFetchedResultsController!.object(at: indexPath)
            let tabBarController = segue.destination as! UITabBarController
            self.initManagedObjectContextInSplitViewControllers(tabBarController, selectedItem:announcement)
            tabBarController.selectedIndex = 2
            announcementTableView.deselectRow(at: indexPath, animated:true)
        }
        else if (segue.identifier == "Show All ILP Assignments Split View") {
            let tabBarController = segue.destination as! UITabBarController
            self.initManagedObjectContextInSplitViewControllers(tabBarController, selectedItem: nil)
            tabBarController.selectedIndex = 0
        }
        else if (segue.identifier == "Show All ILP Events Split View") {
            let tabBarController = segue.destination as! UITabBarController
            self.initManagedObjectContextInSplitViewControllers(tabBarController, selectedItem: nil)
            tabBarController.selectedIndex = 1
        }
        else if (segue.identifier == "Show All ILP Announcements Split View") {
            let tabBarController = segue.destination as! UITabBarController
            self.initManagedObjectContextInSplitViewControllers(tabBarController, selectedItem: nil)
            tabBarController.selectedIndex = 2
        }
        
    }
    
    func initManagedObjectContextInSplitViewControllers(_ tabBarController:UITabBarController, selectedItem:NSObject?)
    {
        for tabbedViewController in tabBarController.viewControllers! {
            
            let splitViewController = tabbedViewController as! UISplitViewController
            
            let navController = splitViewController.viewControllers[0] as! UINavigationController
            let rootViewController = navController.viewControllers[0] as UIViewController
            let detailViewController = splitViewController.viewControllers[1] as UIViewController
            
            if var rootViewController = rootViewController as? ILPAllItemsViewControllerProtocol {
                rootViewController.myManagedObjectContext = self.module?.managedObjectContext
                rootViewController.myTabBarController = tabBarController
                rootViewController.module = self.module
                if let rootViewController = rootViewController as? AllAssignmentsViewController {
                    rootViewController.detailViewController = detailViewController as? CourseAssignmentDetailViewController
                    }
                if let rootViewController = rootViewController as? AllEventsViewController {
                    rootViewController.detailViewController = detailViewController as? CourseEventsDetailViewController
                }
                if let rootViewController = rootViewController as? AllAnnouncementsViewController {
                    rootViewController.detailViewController = detailViewController as? CourseAnnouncementDetailViewController

                }
            }
            
            if selectedItem is CourseAssignment && rootViewController is AllAssignmentsViewController {
                let viewController = rootViewController as! AllAssignmentsViewController
                viewController.selectedAssignment = selectedItem as? CourseAssignment
            }
            if selectedItem is CourseEvent && rootViewController is AllEventsViewController {
                let viewController = rootViewController as! AllEventsViewController
                viewController.selectedEvent = selectedItem as? CourseEvent
            }
            if selectedItem is CourseAnnouncement && rootViewController is AllAnnouncementsViewController {
                let viewController = rootViewController as! AllAnnouncementsViewController
                    viewController.selectedAnnouncement = selectedItem as? CourseAnnouncement
            }
            
            splitViewController.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        }
    }
    
    //iPad Split View Delegate Method for iOS < 8.0
    func splitViewController(_ svc: UISplitViewController,
        shouldHide vc: UIViewController,
        in orientation: UIInterfaceOrientation) -> Bool
    {
        return false;
    }
    
    func initManagedObjectContextInDetailViewControllers(_ tabBarController:UITabBarController)
    {
        for tabbedViewController in tabBarController.viewControllers! {
            if var rootViewController = tabbedViewController as? ILPAllItemsViewControllerProtocol {
                rootViewController.myManagedObjectContext = self.module?.managedObjectContext
                rootViewController.myTabBarController = tabBarController
            }
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        resizeAfterOrientationChange()
    }
    
    func styleCardHeaders() {
        
        let allAssignmentButtonBounds = showAllAssignmentsView.layer.bounds
        let allAssignmentButtonRect:CGRect = CGRect(x:allAssignmentButtonBounds.origin.x, y:allAssignmentButtonBounds.origin.y, width:assignmentTableWidthConstraint.constant, height:allAssignmentButtonBounds.height)
        
        let allEventsButtonBounds = showAllEventsView.layer.bounds
        let allEventsButtonRect:CGRect = CGRect(x:allEventsButtonBounds.origin.x, y:allEventsButtonBounds.origin.y, width:eventTableWidthConstraint.constant, height:allEventsButtonBounds.height)
        
        let allAnnouncementsButtonBounds = showAllAnnouncementsView.layer.bounds
        let allAnnouncementsButtonRect:CGRect = CGRect(x:allAnnouncementsButtonBounds.origin.x, y:allAnnouncementsButtonBounds.origin.y, width:announcementTableWidthConstraint.constant, height:allAnnouncementsButtonBounds.height)
        
        // Create the path (with only the top-left corner rounded
        let assignmentPath = UIBezierPath(roundedRect: allAssignmentButtonRect, byRoundingCorners:[.topLeft, .topRight], cornerRadii: CGSize(width: 3.0, height: 3.0))
        let assignmentMask = CAShapeLayer()
        assignmentMask.path = assignmentPath.cgPath
        showAllAssignmentsView.layer.mask = assignmentMask
        
        // Create the path (with only the top-left corner rounded
        let eventPath = UIBezierPath(roundedRect: allEventsButtonRect, byRoundingCorners:[.topLeft, .topRight], cornerRadii: CGSize(width: 3.0, height: 3.0))
        let eventMask = CAShapeLayer()
        eventMask.path = eventPath.cgPath
        showAllEventsView.layer.mask = eventMask
        
        // Create the path (with only the top-left corner rounded
        let announcementPath = UIBezierPath(roundedRect: allAnnouncementsButtonRect, byRoundingCorners:[.topLeft, .topRight], cornerRadii: CGSize(width: 3.0, height: 3.0))
        let announcementMask = CAShapeLayer()
        announcementMask.path = announcementPath.cgPath
        showAllAnnouncementsView.layer.mask = announcementMask
        
        showAllAssignmentsView.backgroundColor = darkGray
        showAllAnnouncementsView.backgroundColor = darkGray
        showAllEventsView.backgroundColor = darkGray
        
        assignmentCardView.layer.cornerRadius = 5.0
        eventCardView.layer.cornerRadius = 5.0
        announcementCardView.layer.cornerRadius = 5.0
    }
    
    func initIPadPortraitConstraints() {
        
        if ( portraitConstraintArray.count == 0) {
            
            portraitConstraintArray.append(NSLayoutConstraint(item:assignmentCardView, attribute:NSLayoutAttribute.leading, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.leading, multiplier:1.0, constant:cardInsetConstant))
            
            portraitConstraintArray.append(NSLayoutConstraint(item:assignmentCardView, attribute:NSLayoutAttribute.trailing, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.trailing, multiplier:1.0, constant:cardInsetConstant))
            
            portraitConstraintArray.append(NSLayoutConstraint(item:assignmentCardView, attribute:NSLayoutAttribute.top, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.top, multiplier:1.0, constant:cardInsetConstant))
            
            portraitConstraintArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[assignmentCardView]-25-[eventCardView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["assignmentCardView":assignmentCardView, "eventCardView":eventCardView]))
            
            portraitConstraintArray.append(NSLayoutConstraint(item:eventCardView, attribute:NSLayoutAttribute.leading, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.leading, multiplier:1.0, constant:cardInsetConstant))
            
            portraitConstraintArray.append(NSLayoutConstraint(item:eventCardView, attribute:NSLayoutAttribute.trailing, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.trailing, multiplier:1.0, constant:cardInsetConstant))
            
            portraitConstraintArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[eventCardView]-25-[announcementCardView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["eventCardView":eventCardView, "announcementCardView":announcementCardView]))
            
            portraitConstraintArray.append(NSLayoutConstraint(item:announcementCardView, attribute:NSLayoutAttribute.leading, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.leading, multiplier:1.0, constant:cardInsetConstant))
            
            portraitConstraintArray.append(NSLayoutConstraint(item:announcementCardView, attribute:NSLayoutAttribute.trailing, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.trailing, multiplier:1.0, constant:cardInsetConstant))
            
            portraitConstraintArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[announcementCardView]-25-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["announcementCardView":announcementCardView]))
        }
    }
    
    func initIPadLandscapeConstraints() {
        
        if landscapeConstraintArray.count == 0 {
            landscapeConstraintArray.append(NSLayoutConstraint(item:assignmentCardView, attribute:NSLayoutAttribute.leading, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.leading, multiplier:1.0, constant:cardInsetConstant))
            
            landscapeConstraintArray.append(NSLayoutConstraint(item:assignmentCardView, attribute:NSLayoutAttribute.top, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.top, multiplier:1.0, constant:cardInsetConstant))
            
            landscapeConstraintArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[assignmentCardView]->=25-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["assignmentCardView":assignmentCardView]))

            landscapeConstraintArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[assignmentCardView]-25-[eventCardView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["assignmentCardView":assignmentCardView, "eventCardView":eventCardView]))

            landscapeConstraintArray.append(NSLayoutConstraint(item:eventCardView, attribute:NSLayoutAttribute.top, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.top, multiplier:1.0, constant:cardInsetConstant))
            
            landscapeConstraintArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[eventCardView]->=25-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["eventCardView":eventCardView]))
            
            landscapeConstraintArray.append(NSLayoutConstraint(item:announcementCardView, attribute:NSLayoutAttribute.top, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.top, multiplier:1.0, constant:cardInsetConstant))
            
            landscapeConstraintArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[announcementCardView]->=25-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["announcementCardView":announcementCardView]))
            
            landscapeConstraintArray.append(NSLayoutConstraint(item:announcementCardView, attribute:NSLayoutAttribute.trailing, relatedBy:NSLayoutRelation.equal, toItem:scrollView, attribute:NSLayoutAttribute.trailing, multiplier:1.0, constant:cardInsetConstant))
            
            landscapeConstraintArray.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[eventCardView]-25-[announcementCardView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["eventCardView":eventCardView, "announcementCardView":announcementCardView]))
        }
    }
    
    func datetimeFormatter() -> DateFormatter?{
        
        if (self.myDatetimeFormatter != nil)  {
            return self.myDatetimeFormatter
        } else {
            self.myDatetimeFormatter = DateFormatter()
            self.myDatetimeFormatter!.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'";
            self.myDatetimeFormatter!.timeZone = TimeZone(abbreviation:"UTC")
            return self.myDatetimeFormatter
        }
    }
    
    @objc func dataFinishedLoading(_ sender: AnyObject) {
        checkAllUpdated = checkAllUpdated + 1
        // Ensure that all information is updated
        if (checkAllUpdated == 3) {
            checkAllUpdated = 0
            DispatchQueue.main.async {
                if let hudView = self.view {
                    MBProgressHUD.hide(for: hudView, animated: true)
                }
                self.showDetailForRequestedAssignment()
            }
        }
    }
    
    func showDetailForRequestedAssignment() {
        if let requestedAssignmentId = requestedAssignmentId {
            if let _ = self.indexPathForAssignmentWithUrl(requestedAssignmentId) {
                if ( UIDevice.current.userInterfaceIdiom == .pad ) {
                    self.performSegue(withIdentifier: "Show ILP Assignment Split View For Assignment", sender: self)
                } else {
                    self.performSegue(withIdentifier: "Show ILP Assignment Detail", sender: self)
                }
            }
        }
    }
    
    func resizeAfterOrientationChange() {
        var screenWidth = UIScreen.main.bounds.size.width
        if #available(iOS 11, *) {
            screenWidth = screenWidth - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right
            
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            initIPadPortraitConstraints()
            initIPadLandscapeConstraints()
            
            switch UIDevice.current.orientation{
            case .portrait:
                scrollView.removeConstraints(landscapeConstraintArray)
                scrollView.addConstraints(portraitConstraintArray)
                assignmentTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                announcementTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                eventTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
            case .portraitUpsideDown:
                scrollView.removeConstraints(landscapeConstraintArray)
                scrollView.addConstraints(portraitConstraintArray)
                assignmentTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                announcementTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                eventTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
            case .landscapeLeft:
                scrollView.removeConstraints(portraitConstraintArray)
                scrollView.addConstraints(landscapeConstraintArray)
                assignmentTableWidthConstraint.constant = (screenWidth - 100)/3
                announcementTableWidthConstraint.constant = (screenWidth - 100)/3
                eventTableWidthConstraint.constant = (screenWidth - 100)/3
            case .landscapeRight:
                scrollView.removeConstraints(portraitConstraintArray)
                scrollView.addConstraints(landscapeConstraintArray)
                assignmentTableWidthConstraint.constant = (screenWidth - 100)/3
                announcementTableWidthConstraint.constant = (screenWidth - 100)/3
                eventTableWidthConstraint.constant = (screenWidth - 100)/3
            default:
                scrollView.removeConstraints(landscapeConstraintArray)
                scrollView.addConstraints(portraitConstraintArray)
                assignmentTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                announcementTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
                eventTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
            }
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            assignmentTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
            eventTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
            announcementTableWidthConstraint.constant = screenWidth - (cardInsetConstant * 2.0)
        }
        styleCardHeaders()
    }
    
    
    func indexPathForAssignmentWithUrl(_ requestedAssignmentId: String?) -> IndexPath? {
        if let requestedAssignmentId = requestedAssignmentId {
            if let assignmentsFetchedResultController = assignmentsFetchedResultController {
                for iter in assignmentsFetchedResultController.fetchedObjects!
                {
                    let temp: CourseAssignment = iter
                    if temp.url != nil {
                        if temp.url == requestedAssignmentId {
                            return assignmentsFetchedResultController.indexPath(forObject: temp)
                        }
                    }
                }
            }
        }
        return nil
    }
}
