//
//  CourseDetailViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 10/26/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class CourseDetailViewController: UITableViewController, CourseDetailViewControllerProtocol {
    
    var module : Module?
    var termId : String?
    var sectionId : String?
    var courseName : String?
    var courseSectionNumber : String?

    
    static let CourseDetailInformationLoadedNotification = Notification.Name("CourseDetailInformationLoaded")

    var courseDetail : CourseDetail?
    
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
    let displayDateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone(abbreviation:"UTC")
        return formatter
    }()
    let shortDisplayDateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("Md")
        formatter.timeZone = TimeZone(abbreviation:"UTC")
        return formatter
    }()
    let displayTimeFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    var instructors : [CourseDetailInstructor]?
    var meetingPatterns : [CourseMeetingPattern]?
    var buildingsUrl : String?
    var directoryUrl : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(CourseDetailViewController.setupData), name: CourseDetailViewController.CourseDetailInformationLoadedNotification, object: nil)
        self.navigationItem.title = self.courseNameAndSectionNumber()
        
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        
        let defaults = AppGroupUtilities.userDefaults()
        if ConfigurationManager.doesMobileServerSupportVersion("4.5") {
            directoryUrl = defaults?.string(forKey: "urls-directory-baseSearch")
        } else {
            directoryUrl = defaults?.string(forKey: "urls-directory-facultySearch")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch((indexPath as NSIndexPath).section) {
        case 0:
            return 60
        case 1:
            return 60
        default:
            return 120;
        }
        
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _ = self.courseDetail {
            switch(section) {
            case 0:
                if let count = self.meetingPatterns?.count , count > 0 {
                    return count
                }
                return 1
            case 1:
                if let count = self.instructors?.count , count > 0 {
                    return count
                }
                return 1
            case 2:
                return courseDetail?.courseDescription != nil ? 1 : 0;
            default:
                return 0;
            }
        }
        return 0;
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let _ = self.courseDetail {
            switch(section) {
            case 0:
                return 52
            case 1:
                return 30
            case 2:
                return 0
            default:
                return 1
            }
        }
        return 0
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if let _ = self.courseDetail {
            switch(section) {
            case 0:
                return headerForTitle()
            case 1:
                return headerForFaculty()
            case 2:
                return nil;
            default:
                return nil;
            }
        }
        return nil;
    }
    
    func headerForTitle() -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
        let label = UILabel(frame: CGRect(x: 8,y: 0,width: tableView.frame.width, height: 30))
        label.translatesAutoresizingMaskIntoConstraints = false
        let label2 = UILabel(frame: CGRect(x: 8,y: 30,width: tableView.frame.width, height: 30))
        label2.translatesAutoresizingMaskIntoConstraints = false
        
        
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        label2.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        view.backgroundColor = UIColor(rgba: "#e6e6e6")
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        label2.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
        
        view.addSubview(label)
        view.addSubview(label2)
        
        let viewsDictionary = ["label": label, "label2": label2, "view": view]
        
        // Create and add the vertical constraints
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-4-[label]-4-[label2]-4-|",
            options: NSLayoutFormatOptions.alignAllLeading,
            metrics: nil,
            views: viewsDictionary))
        
        // Create and add the horizontal constraints
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[label]",
            options: .alignAllLastBaseline,
            metrics: nil,
            views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[label2]",
            options: .alignAllLastBaseline,
            metrics: nil,
            views: viewsDictionary))
        
        label.text = self.courseDetail!.sectionTitle;
        if let courseDetail = courseDetail, let firstMeetingDate = courseDetail.firstMeetingDate, let lastMeetingDate = courseDetail.lastMeetingDate {
            let dates = String(format: NSLocalizedString("course first meeting - last meeting", tableName: "Localizable", bundle: Bundle.main, value: "%@ - %@", comment: "course first meeting - last meeting"), self.displayDateFormatter.string(from: firstMeetingDate), self.displayDateFormatter.string(from: lastMeetingDate))
            label2.text = dates
        }
        return view;
    }
    
    func headerForFaculty() -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
        let label = UILabel(frame: CGRect(x: 8,y: 0,width: tableView.frame.width, height: 30))
        label.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        label.text = NSLocalizedString("Faculty", comment:"Faculty label")
        return view;
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sendView("Course Overview", moduleName: self.module!.name)
    }
    
    @IBAction func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func setupData() {
        let defaults = AppGroupUtilities.userDefaults()
        self.buildingsUrl = defaults?.string(forKey: "urls-map-buildings")
        let request = NSFetchRequest<CourseDetail>(entityName: "CourseDetail")
        request.predicate = NSPredicate(format: "termId == %@ && sectionId == %@", self.termId!, self.sectionId!)
        
        self.courseDetail = try! self.module!.managedObjectContext!.fetch(request).last
        if let courseDetail = self.courseDetail {
            self.instructors = courseDetail.instructors.array as? [CourseDetailInstructor]
            self.meetingPatterns = courseDetail.meetingPatterns.array as? [CourseMeetingPattern]
        }
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : UITableViewCell
        
        switch (indexPath as NSIndexPath).section {
        case 0:
            if let count = self.meetingPatterns?.count, count > 0 {
                let meetingPattern = self.meetingPatterns![(indexPath as NSIndexPath).row]
                cell = tableView.dequeueReusableCell(withIdentifier: "Course Detail Meeting Pattern Cell", for: indexPath) as UITableViewCell
                cell.isUserInteractionEnabled = true
                let label = cell.viewWithTag(1) as! UILabel
                let label2 = cell.viewWithTag(2) as! UILabel
                let campusLabel = cell.viewWithTag(4) as! UILabel
                
                var daysOfClass = meetingPattern.daysOfWeek.components(separatedBy: ",") as [String]
                var shortStandaloneWeekdaySymbols = self.dateFormatter.shortStandaloneWeekdaySymbols
                var localizedDays = [String]()
                for i in 0 ..< daysOfClass.count {
                    let value = Int(daysOfClass[i])! - 1
                    localizedDays.append((shortStandaloneWeekdaySymbols?[value])!)
                }
                
                //time
                let days: String = String(format: NSLocalizedString("days:", tableName: "Localizable", bundle: Bundle.main, value:"%@: ", comment: "days:"), localizedDays.joined(separator: ", "))
                var line1: String
                let sectionDatesMatchesMeetingPatternDates = (meetingPattern.startDate == self.courseDetail?.firstMeetingDate) && (meetingPattern.endDate == self.courseDetail?.lastMeetingDate)
                
                if meetingPattern.instructionalMethodCode != nil {
                    if sectionDatesMatchesMeetingPatternDates {
                        line1 = String(format: NSLocalizedString("days start - end method", tableName: "Localizable", bundle: Bundle.main, value: "%@ %@ - %@ %@", comment: "days start - end method"), days, self.displayTimeFormatter.string(from: meetingPattern.startTime), self.displayTimeFormatter.string(from: meetingPattern.endTime), meetingPattern.instructionalMethodCode)
                    } else {
                        if meetingPattern.startDate == meetingPattern.endDate {
                            line1 = String(format: NSLocalizedString("days startdate starttime - endtime method", tableName: "Localizable", bundle: Bundle.main, value: "%@ %@ %@ - %@ %@", comment: "days startdate starttime - endtime method"), days, self.shortDisplayDateFormatter.string(from: meetingPattern.startDate), self.displayTimeFormatter.string(from: meetingPattern.startTime), self.displayTimeFormatter.string(from: meetingPattern.endTime), meetingPattern.instructionalMethodCode)
                        } else {
                            line1 = String(format: NSLocalizedString("days startdate - enddate starttime - endtime method", tableName: "Localizable", bundle: Bundle.main, value: "%@ %@ - %@ %@ - %@ %@", comment: "days startdate - enddate starttime - endtime method"), days, self.shortDisplayDateFormatter.string(from: meetingPattern.startDate), self.shortDisplayDateFormatter.string(from: meetingPattern.endDate), self.displayTimeFormatter.string(from: meetingPattern.startTime), self.displayTimeFormatter.string(from: meetingPattern.endTime), meetingPattern.instructionalMethodCode)
                        }
                    }
                }
                else {
                    if sectionDatesMatchesMeetingPatternDates {
                        line1 = String(format: NSLocalizedString("days start - end", tableName: "Localizable", bundle: Bundle.main, value:"%@ %@ - %@", comment:"days start - end"), days, self.displayTimeFormatter.string(from: meetingPattern.startTime), self.displayTimeFormatter.string(from: meetingPattern.endTime))
                    } else {
                        if meetingPattern.startDate == meetingPattern.endDate {
                            line1 = String(format: NSLocalizedString("days startdate starttime - endtime", tableName: "Localizable", bundle: Bundle.main, value:"%@ %@ %@ - %@", comment:"days startdate starttime - endtime"), days, self.shortDisplayDateFormatter.string(from: meetingPattern.startDate), self.displayTimeFormatter.string(from: meetingPattern.startTime), self.displayTimeFormatter.string(from: meetingPattern.endTime))
                        } else {
                            line1 = String(format: NSLocalizedString("days startdate - enddate starttime - endtime", tableName: "Localizable", bundle: Bundle.main, value:"%@ %@ - %@ %@ - %@", comment:"days startdate - enddate starttime - endtime"), days, self.shortDisplayDateFormatter.string(from: meetingPattern.startDate), self.shortDisplayDateFormatter.string(from: meetingPattern.endDate), self.displayTimeFormatter.string(from: meetingPattern.startTime), self.displayTimeFormatter.string(from: meetingPattern.endTime))
                        }
                    }
                }
                
                let attributedLine1: NSMutableAttributedString = NSMutableAttributedString(string: line1)
                attributedLine1.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline), range: NSMakeRange(0, days.count))
                label.translatesAutoresizingMaskIntoConstraints = false
                label.attributedText = attributedLine1
                
                //location
                var location: String = ""
                if meetingPattern.building != nil && meetingPattern.room != nil {
                    location = String(format: NSLocalizedString("%@, Room %@", comment: "label - building name, room number"), meetingPattern.building, meetingPattern.room)
                }
                else {
                    if let _ = meetingPattern.building {
                        location = meetingPattern.building
                    }
                    else {
                        if let _ = meetingPattern.room {
                            location = String(format: NSLocalizedString("Room %@", comment: "label - room number"), meetingPattern.room)
                        }
                    }
                }
 
                if let campusName = meetingPattern.campus {
                    campusLabel.text = campusName;
                    cell.isUserInteractionEnabled = true
                }
                else if let campusId = meetingPattern.campusId {
                    campusLabel.text = campusId;
                    cell.isUserInteractionEnabled = true
                } else {
                    campusLabel.text = ""
                    cell.isUserInteractionEnabled = false //no building location so don't allow segue to it
                }
                
                if let _ = self.buildingsUrl, let _ = meetingPattern.buildingId {
                    let underlineAttributes : [NSAttributedStringKey : Any] = [NSAttributedStringKey(rawValue: NSAttributedStringKey.underlineStyle.rawValue): NSUnderlineStyle.styleSingle.rawValue,
                                                                               NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): UIColor.primary]
                    let underlineAttributedString = NSAttributedString(string: location, attributes: underlineAttributes)
                    label2.attributedText = underlineAttributedString
                    
                } else {
                    label2.text = location
                }
                
                let imageView = cell.viewWithTag(3)
                if let label2 = label2.text , !label2.isEmpty {
                    imageView!.tintColor = UIColor.primary
                } else {
                    imageView?.removeFromSuperview()
                }
                
                
                
                
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "Course Detail No Meeting Pattern Cell", for: indexPath) as UITableViewCell
                cell.isUserInteractionEnabled = false
            }
            
        case 1:
            if self.instructors!.count > 0 {
                let instructor = self.instructors![(indexPath as NSIndexPath).row]
                cell = tableView.dequeueReusableCell(withIdentifier: "Course Detail Instructor Cell", for: indexPath) as UITableViewCell
                let label = cell.viewWithTag(1) as! UILabel
                label.text = instructor.formattedName
                if let _ = directoryUrl {
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.isUserInteractionEnabled = false
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "Course Detail No Instructor Cell", for: indexPath) as UITableViewCell
                cell.isUserInteractionEnabled = false
            }
            
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "Course Detail Description Cell", for: indexPath) as UITableViewCell
            let label = cell.viewWithTag(1) as! UILabel
            label.text = courseDetail?.courseDescription
            cell.isUserInteractionEnabled = false
        default:
            cell = UITableViewCell()
        }
        
        cell.layoutIfNeeded()
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath as NSIndexPath).section {
        case 0:
            let mp: CourseMeetingPattern = self.meetingPatterns![(indexPath as NSIndexPath).row]
            self.performSegue(withIdentifier: "Show Course Location", sender: mp.buildingId)
        case 1:
            
            let instructor = self.instructors![(indexPath as NSIndexPath).row]
            let name : String
            if instructor.firstName != nil  && instructor.lastName != nil  {
                name = instructor.firstName + " " + instructor.lastName
            } else if instructor.firstName != nil  {
                name = instructor.firstName
            } else if instructor.lastName != nil {
                name = instructor.lastName
            } else {
                name = instructor.formattedName
            }
            
            let encodedSearchString = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let encodedIdString = instructor.instructorId.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let urlString = "\(directoryUrl!)?searchString=\(encodedSearchString!)&targetId=\(encodedIdString!)"
            let authenticatedRequest = AuthenticatedRequest()
            var entries = [DirectoryEntry]()
            if let responseData = authenticatedRequest.requestURL(URL(string: urlString)!, fromView: self) {
                entries = DirectoryEntry.parseResponse(responseData)
            }
            
            if entries.count == 0 {
                let alertController = UIAlertController(title: NSLocalizedString("Faculty", comment: "title for faculty no match"), message: NSLocalizedString("Person was not found", comment: "Person was not found"), preferredStyle: .alert)
                let OKAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion: nil)
            } else if entries.count == 1 {
                self.performSegue(withIdentifier: "Show Faculty Person", sender: entries[0])
            } else {
                self.performSegue(withIdentifier: "Show Faculty List", sender: entries)
            }
            
            
        case 2:
            ()
        default:
            ()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "Show Course Location" {
            self.sendEventToTracker1(category: .ui_Action, action: .list_Select, label: "Map Detail", moduleName: self.module!.name)
            let vc = segue.destination as! POIDetailViewController
            vc.buildingId = sender as? String
            vc.module = self.module
        } else if segue.identifier == "Show Faculty List" {
            let detailController = segue.destination as! DirectoryViewController
            detailController.entries = sender as! [DirectoryEntry];
            detailController.module = self.module;
        } else if segue.identifier == "Show Faculty Person" {
            let detailController = segue.destination as! DirectoryEntryViewController
            detailController.entry = sender as? DirectoryEntry;
            detailController.module = self.module;
        }
    }
}
