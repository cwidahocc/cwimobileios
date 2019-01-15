//
//  CourseDetailTabBarController.swift
//  Mobile
//
//  Created by Jason Hocker on 10/23/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class CourseDetailTabBarController : UITabBarController, CourseDetailViewControllerProtocol, UINavigationControllerDelegate {

    var module : Module?
    var isInstructor : Bool?
    var termId : String?
    var sectionId : String?
    var courseName : String?
    var courseSectionNumber : String?
    
    let dateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation:"UTC")
        return formatter
    }()
    let timeFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "HH:mm'Z'"
        formatter.timeZone = TimeZone(abbreviation:"UTC")
        return formatter
    }()
    let tzTimeFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "HH:mm'Z'"
        return formatter
    }()
    var originalViewControllers : [UIViewController]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let navBarController = self.moreNavigationController
        navBarController.navigationBar.barTintColor = UIColor.primary
        self.originalViewControllers = self.viewControllers
        self.renderTabs()
        self.fetchCourseDetail(self)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let morenavbar: UINavigationBar? = navigationController.navigationBar
        let morenavitem: UINavigationItem? = morenavbar?.topItem
        viewController.view.tintColor = UIColor.primary
        /* We don't need Edit button in More screen. */
        morenavitem?.rightBarButtonItem = nil
    }

    
    func renderTabs() {
        let request = NSFetchRequest<CourseDetail>(entityName: "CourseDetail")
        request.predicate = NSPredicate(format: "termId == %@ && sectionId == %@", self.termId!, self.sectionId!)
        var tempArray = [UIViewController]()
        tempArray.append(self.originalViewControllers![0])
        tempArray.append(self.originalViewControllers![1])
        var rosterVisible = self.module!.property(forKey: "visible")
        //for backwards compatible to the way data was stored before 3.0.
        if rosterVisible == nil {
            rosterVisible = self.module!.property(forKey: "rosterVisible")
        }
        if !((rosterVisible == "none") || rosterVisible == "faculty" && !self.isInstructor! ) {
            tempArray.append(self.originalViewControllers![2])
        }
        
        if let _ = self.module!.property(forKey: "ilp") {
            tempArray.append(self.originalViewControllers![3])
            tempArray.append(self.originalViewControllers![4])
            tempArray.append(self.originalViewControllers![5])
        }
        self.viewControllers = tempArray
        self.customizableViewControllers = nil
        let navBarController: UINavigationController = self.moreNavigationController
        navBarController.navigationBar.barTintColor = UIColor.primary
        self.moreNavigationController.delegate = self
    }

    func fetchCourseDetail(_ sender: AnyObject) {
        
        if let userid = CurrentUser.sharedInstance.userid {
            let urlBase = self.module?.property(forKey: "overview")
            let escapedUserId = userid.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let escapedTermId = self.termId?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let escapedSectionId = self.sectionId?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let urlString = "\(urlBase!)/\(escapedUserId!)?term=\(escapedTermId!)&section=\(escapedSectionId!)"
            
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.parent = self.module?.managedObjectContext
            privateContext.undoManager = nil
            
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
            hud.label.text = loadingString
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
            
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
                        
                        let request = NSFetchRequest<CourseDetail>(entityName: "CourseDetail")

                        request.predicate = NSPredicate(format: "termId == %@ && sectionId == %@", self.termId!, self.sectionId!)
                        let oldObjects = try privateContext.fetch(request)
                        for oldObject in oldObjects {
                            privateContext.delete(oldObject)
                        }
                        
                        if let jsonTerms = json["terms"].array {
                            for jsonTerm in jsonTerms {
                                if let jsonSections = jsonTerm["sections"].array {
                                    for jsonSection in jsonSections {
                                        let courseDetail = NSEntityDescription.insertNewObject(forEntityName: "CourseDetail", into: privateContext) as! CourseDetail
                                        courseDetail.termId = self.termId!
                                        courseDetail.sectionId = jsonSection["sectionId"].string
                                        if let sectionTitle = jsonSection["sectionTitle"].string {
                                            courseDetail.sectionTitle = sectionTitle
                                        }
                                        if let courseName = jsonSection["courseName"].string {
                                            courseDetail.courseName = courseName
                                        }
                                        if let courseDescription = jsonSection["courseDescription"].string {
                                            courseDetail.courseDescription = courseDescription
                                        }
                                        if let courseSectionNumber = jsonSection["courseSectionNumber"].string {
                                            courseDetail.courseSectionNumber = courseSectionNumber
                                        }
                                        if let firstMeetingDate = jsonSection["firstMeetingDate"].string {
                                            let date = self.dateFormatter.date(from: firstMeetingDate)
                                            courseDetail.firstMeetingDate = date
                                        }
                                        if let lastMeetingDate = jsonSection["lastMeetingDate"].string {
                                            let date = self.dateFormatter.date(from: lastMeetingDate)
                                            courseDetail.lastMeetingDate = date
                                        }
                                        
                                        if let jsonInstructors = jsonSection["instructors"].array {
                                            for jsonInstructor in jsonInstructors {
                                                let instructor = NSEntityDescription.insertNewObject(forEntityName: "CourseDetailInstructor", into: privateContext) as! CourseDetailInstructor
                                                if let firstName = jsonInstructor["firstName"].string {
                                                    instructor.firstName = firstName
                                                }
                                                if let lastName = jsonInstructor["lastName"].string {
                                                    instructor.lastName = lastName
                                                }
                                                if let middleInitial = jsonInstructor["middleInitial"].string {
                                                    instructor.middleInitial = middleInitial
                                                }
                                                instructor.instructorId = jsonInstructor["instructorId"].string
                                                instructor.primary = jsonInstructor["primary"] == true ? 1 : 0
                                                instructor.formattedName = jsonInstructor["formattedName"].string
                                                instructor.course = courseDetail
                                                courseDetail.addInstructorsObject(instructor)
                                                
                                            }
                                            
                                        }
                                        if let learningProvider = jsonSection["learningProvider"].string {
                                            courseDetail.learningProvider = learningProvider
                                        }
                                        if let learningProviderSiteId = jsonSection["learningProviderSiteId"].string {
                                            courseDetail.learningProviderSiteId = learningProviderSiteId
                                        }
                                        if let primarySectionId = jsonSection["primarySectionId"].string {
                                            courseDetail.primarySectionId = primarySectionId
                                        }
                                        
                                        if let jsonMeetingPatterns = jsonSection["meetingPatterns"].array {
                                                for jsonMeetingPattern in jsonMeetingPatterns {
                                                    let mp = NSEntityDescription.insertNewObject(forEntityName: "CourseMeetingPattern", into: privateContext) as! CourseMeetingPattern
                                                    if let instructionalMethodCode = jsonMeetingPattern["instructionalMethodCode"].string {
                                                        mp.instructionalMethodCode = instructionalMethodCode
                                                    }
                                                    mp.startDate = self.dateFormatter.date(from: jsonMeetingPattern["startDate"].string!)
                                                    mp.endDate = self.dateFormatter.date(from: jsonMeetingPattern["endDate"].string!)
                                                    if let startTime = jsonMeetingPattern["startTime"].string {
                                                        let time = self.timeFormatter.date(from: startTime)
                                                        mp.startTime = time
                                                    }
                                                    if let endTime = jsonMeetingPattern["endTime"].string {
                                                        let time = self.timeFormatter.date(from: endTime)
                                                        mp.endTime = time
                                                    }
                                                    if let sisStartTimeWTz = jsonMeetingPattern["sisStartTimeWTz"].string {
                                                        var components = sisStartTimeWTz.split { $0 == " " }.map(String.init)
                                                        self.tzTimeFormatter.timeZone = TimeZone(identifier: components[1])
                                                        let time = self.tzTimeFormatter.date(from: components[0])
                                                        mp.startTime = time
                                                    }
                                                    if let sisEndTimeWTz = jsonMeetingPattern["sisEndTimeWTz"].string {
                                                        var components = sisEndTimeWTz.split { $0 == " " }.map(String.init)
                                                        self.tzTimeFormatter.timeZone = TimeZone(identifier: components[1])
                                                        let time = self.tzTimeFormatter.date(from: components[0])
                                                        mp.endTime = time
                                                    }
                                                    
                                                    
                                                    let days = jsonMeetingPattern["daysOfWeek"].array!.map{
                                                        String($0.intValue)}
                                                    mp.daysOfWeek = days.joined(separator: ",")
                                                    
                                                    if let room = jsonMeetingPattern["room"].string {
                                                        mp.room = room
                                                    }
                                                    if let building = jsonMeetingPattern["building"].string {
                                                        mp.building = building
                                                    }
                                                    if let buildingId = jsonMeetingPattern["buildingId"].string {
                                                        mp.buildingId = buildingId
                                                    }
                                                    if let campusId = jsonMeetingPattern["campusId"].string {
                                                        mp.campusId = campusId
                                                    }
                                                    mp.course = courseDetail
                                                    if let campus = jsonMeetingPattern["campus"].string {
                                                        mp.campus = campus
                                                    }
                                                    courseDetail.addMeetingPatternsObject(mp)
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
                            self.renderTabs()
                            NotificationCenter.default.post(name: CourseDetailViewController.CourseDetailInformationLoadedNotification, object: nil)
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
