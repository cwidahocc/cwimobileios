//
//  CoursesCalendarViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 10/14/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class CoursesCalendarViewController : UIViewController, UIPickerViewDelegate, EllucianMobileLaunchableControllerProtocol, CalendarViewDayViewDataSource, CalendarViewDayViewDelegate {
 
    @IBOutlet weak var datePickerButton: UIButton!
    
    var module : Module!
    var datePickerContainer : UIView?
    var datePicker : UIDatePicker?
    
    let timeFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    let dateFormatterISO8601 : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation:"UTC")
        return formatter
    }()
    let dateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var cachedData = [CalendarViewEvent]()
    var fetchedDates = [String]()
    var hud : MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dayView = self.view as? CalendarViewDayView
        dayView!.autoScrollToFirstEvent = true
        self.navigationItem.title = self.module!.name
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sendView("Schedule (daily view)", moduleName: self.module?.name)
        let dayView = self.view as? CalendarViewDayView
        dayView!.reloadData()
    }
    
    func reloadScheduleNotification(_ notification: Notification) {
        let dayView = self.view as? CalendarViewDayView
        dayView!.reloadData()
    }

    func dayView(_ dayView: CalendarViewDayView!, eventsFor date: Date!) -> [Any]! {
        var hud : MBProgressHUD? = nil
        if let userid = CurrentUser.sharedInstance.userid {
            let startDate: Date = date.addingTimeInterval(-86400.0)
            let endDate: Date = date.addingTimeInterval((86400.0 * 7.0))
            let startFormattedString: String = dateFormatter.string(from: startDate)
            let endFormattedString: String = dateFormatter.string(from: endDate)
            let thisFormattedDate: String = dateFormatter.string(from: date)
            
            if !self.fetchedDates.contains(thisFormattedDate) {
                DispatchQueue.main.async(execute: {
                    hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
                    hud?.label.text = loadingString
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
                })
                
                let urlPrefix = self.module!.property(forKey: "daily")
                let encodedUserId = userid.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                let encodedStart = startFormattedString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                let encodedEnd = endFormattedString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                let urlString: String = "\(urlPrefix!)/\(encodedUserId!)?start=\(encodedStart!)&end=\(encodedEnd!)"
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                
                let authenticatedRequest = AuthenticatedRequest()
                if let responseData = authenticatedRequest.requestURL(URL(string: urlString), fromView: self) {
                    
                    
                    let json = JSON(data: responseData)
                    let courseDays = json["coursesDays"].arrayValue
                    for dateJson in courseDays {
                        if let date = dateFormatter.date(from: dateJson["date"].stringValue) {
                            let dateString = dateFormatter.string(from: date)
                            if dateString.isEqual(startFormattedString) || dateString.isEqual(endFormattedString) {
                                //At the edges of the response, do not include as fully fetched date
                            }
                            else {
                                self.fetchedDates.append(dateString)
                            }
                            
                            for meetingJson in dateJson["coursesMeetings"].arrayValue {
                                let event = CalendarViewEvent()
                                event.allDay = false
                                let sectionTitle: String = meetingJson["sectionTitle"].stringValue
                                let courseName: String = meetingJson["courseName"].stringValue
                                let courseSectionNumber: String = meetingJson["courseSectionNumber"].stringValue
                                let localizedFormat = NSLocalizedString("course calendar course name-course section - title", tableName: "Localizable", bundle: Bundle.main, value: "%@-%@ - %@", comment: "course calendar course name-course section - title") as String
                                event.line1 = String(format:localizedFormat, courseName, courseSectionNumber, sectionTitle)
                                let startDate = dateFormatterISO8601.date(from: meetingJson["start"].stringValue)
                                let endDate = dateFormatterISO8601.date(from: meetingJson["end"].stringValue)
                                
                                let startLabel: String = timeFormatter.string(from: startDate!)
                                let endLabel: String = timeFormatter.string(from: endDate!)
                                if meetingJson["building"].string != nil && meetingJson["room"] != nil {
                                    event.line3 = String(format:NSLocalizedString("course event start - end date", tableName: "Localizable", bundle: Bundle.main, value: "%@ - %@", comment: "course event start - end date"), startLabel, endLabel)
                                    event.line2 = String(format:NSLocalizedString("%@, Room %@", comment: "label - building name, room number"), meetingJson["building"].stringValue, meetingJson["room"].stringValue)
                                } else if meetingJson["building"] != nil{
                                    event.line3 = String(format:NSLocalizedString("course event start - end date", tableName: "Localizable", bundle: Bundle.main, value: "%@ - %@", comment: "course event start - end date"), startLabel, endLabel)
                                    event.line2 = meetingJson["building"].stringValue
                                } else if meetingJson["room"] != nil {
                                    event.line3 = String(format:NSLocalizedString("course event start - end date", tableName: "Localizable", bundle: Bundle.main, value: "%@ - %@", comment: "course event start - end date"), startLabel, endLabel)
                                    event.line2 = String(format:NSLocalizedString("Room %@", comment: "label - room number"), meetingJson["room"].stringValue)
                                } else {event.line2 = String(format:NSLocalizedString("course event start - end date", tableName: "Localizable", bundle: Bundle.main, value: "%@ - %@", comment: "course event start - end date"), startLabel, endLabel)
                                }
                                
                                event.start = startDate
                                event.end = endDate
                                
                                event.userInfo = [ "courseName":meetingJson["courseName"].stringValue, "sectionId":meetingJson["sectionId"].stringValue, "termId":meetingJson["termId"].stringValue, "isInstructor":meetingJson["isInstructor"].boolValue, "courseSectionNumber":meetingJson["courseSectionNumber"].stringValue]
                                if !self.cachedData.contains(event) {
                                    self.cachedData.append(event)
                                }
                                
                            }
                            
                        }
                        
                    }
                } else {
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment:"title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment:"message when data cannot load due to a poor netwrok connection"), preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: UIAlertActionStyle.default)
                        alertController.addAction(alertAction)
                        self.present(alertController, animated: true)
                    }
                }
                DispatchQueue.main.async(execute: {
                    if let hud = hud {
                        hud.hide(animated: true)
                    }
                })
            }
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
        return self.cachedData
    }
    
    func dayView(_ dayView: CalendarViewDayView!, eventTapped event: CalendarViewEvent!) {
        self.sendEventToTracker1(category: .courses, action: .button_Press, label: "Click Course", moduleName: self.module?.name)
        self.performSegue(withIdentifier: "Show Course Detail", sender: event)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "Show Course Detail" {
            let viewEvent = sender as! CalendarViewEvent
            var userInfo : [AnyHashable : Any] = viewEvent.userInfo
            let tabBarController = segue.destination as! CourseDetailTabBarController
            tabBarController.isInstructor = userInfo["isInstructor"] as? Bool
            tabBarController.module = self.module
            tabBarController.termId = userInfo["termId"] as? String
            tabBarController.sectionId = userInfo["sectionId"] as? String
            tabBarController.courseName = userInfo["courseName"] as? String
            tabBarController.courseSectionNumber = userInfo["courseSectionNumber"] as? String

            for v in tabBarController.viewControllers! {
                var vc: UIViewController = v
                if let navVC = v as? UINavigationController {
                    vc = navVC.viewControllers[0]
                }
                if let vc = vc as? CourseDetailViewControllerProtocol {
                    vc.module = self.module
                    vc.sectionId = userInfo["sectionId"] as? String
                    vc.termId = userInfo["termId"] as? String
                    vc.courseName = userInfo["courseName"] as? String
                    vc.courseSectionNumber = userInfo["courseSectionNumber"] as? String
                }
            }
        } else if segue.identifier == "Show Date Picker" {
            segue.destination.popoverPresentationController?.sourceRect = CGRect(x:
                datePickerButton.frame.size.width/2, y: datePickerButton.frame.size.height, width: 0, height: 0)
            segue.destination.popoverPresentationController?.sourceView = datePickerButton
            
            let destination = segue.destination
            if let pickerController = destination.childViewControllers[0] as? CoursesCalendarDatePickerController {
                pickerController.delegate = self
                let dayView = self.view as? CalendarViewDayView
                pickerController.date = dayView!.day
            }
        }
    }
}
