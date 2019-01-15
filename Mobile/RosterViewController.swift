//
//  RosterViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 10/30/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import Contacts

class RosterViewController : UITableViewController, NSFetchedResultsControllerDelegate, CourseDetailViewControllerProtocol {
    
    var module : Module?
    var termId : String?
    var sectionId : String?
    var courseName : String?
    var courseSectionNumber : String?

    var _fetchedResultsController : NSFetchedResultsController<CourseRoster>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.sectionIndexBackgroundColor = UIColor.clear
        
        try! self.fetchedResultsController.performFetch()
        self.navigationItem.title = self.courseNameAndSectionNumber()
        self.fetchRoster(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sendView( "Course roster list", moduleName: self.module!.name)
    }
    
    var fetchedResultsController: NSFetchedResultsController<CourseRoster> {
        // return if already initialized
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = self.module!.managedObjectContext!
        
        let request = NSFetchRequest<CourseRoster>(entityName: "CourseRoster")
        request.predicate = NSPredicate(format: "termId == %@ && sectionId == %@", self.termId!, self.sectionId!)
        
        switch CNContactsUserDefaults.shared().sortOrder {
        case .none, .userDefault, .familyName:
            request.sortDescriptors = [NSSortDescriptor(key: "lastName", ascending: true), NSSortDescriptor(key: "firstName", ascending: true), NSSortDescriptor(key: "middleName", ascending: true)]
            
        case .givenName:
            request.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true), NSSortDescriptor(key: "lastName", ascending: true), NSSortDescriptor(key: "middleName", ascending: true)]
        }
        
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "sectionKey", cacheName: nil)
        aFetchedResultsController.delegate = self
        self._fetchedResultsController = aFetchedResultsController
        
        do {
            try self._fetchedResultsController!.performFetch()
            
        } catch let error {
            print("fetch error: \(error)")
        }
        
        return self._fetchedResultsController!
    }
    
    @IBAction func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return UILocalizedIndexedCollation.current().sectionIndexTitles
    }
    
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let localizedIndex: Int = UILocalizedIndexedCollation.current().section(forSectionIndexTitle: index)
        var localizedIndexTitles = UILocalizedIndexedCollation.current().sectionIndexTitles
        for currentLocalizedIndex in stride(from: localizedIndex, to: 0, by: -1) {
            for frcIndex in 0 ..< fetchedResultsController.sections!.count {
                let sectionInfo: NSFetchedResultsSectionInfo = fetchedResultsController.sections![frcIndex]
                let indexTitle: String = sectionInfo.indexTitle!
                if indexTitle == localizedIndexTitles[currentLocalizedIndex] {
                    return frcIndex
                }
            }
        }
        return 0
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections![section].name
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as NSFetchedResultsSectionInfo
            let count = currentSection.numberOfObjects
            return count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let roster = fetchedResultsController.object(at: indexPath)
        let defaults = AppGroupUtilities.userDefaults()
        var urlString : String?
        
        if ConfigurationManager.doesMobileServerSupportVersion("4.5") {
            urlString = defaults?.string(forKey: "urls-directory-baseSearch")
        } else {
            urlString = defaults?.string(forKey: "urls-directory-studentSearch")
        }
        
        let name : String
        if roster.firstName != nil  && roster.lastName != nil  {
            name = roster.firstName + " " + roster.lastName
        } else if roster.firstName != nil  {
            name = roster.firstName
        } else if roster.lastName != nil {
            name = roster.lastName
        } else {
            name = roster.name
        }
        
        let encodedSearchString = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let encodedIdString = roster.studentId.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        urlString = "\(urlString!)?searchString=\(encodedSearchString!)&targetId=\(encodedIdString!)"
        let authenticatedRequest = AuthenticatedRequest()
        var entries = [DirectoryEntry]()
        if let responseData = authenticatedRequest.requestURL(URL(string: urlString!)!, fromView: self) {
            entries = DirectoryEntry.parseResponse(responseData)
        }
        
        if entries.count == 0 {
            let alertController = UIAlertController(title: NSLocalizedString("Roster", comment: "title for roster no match"), message: NSLocalizedString("Person was not found", comment: "Person was not found"), preferredStyle: .alert)
            let OKAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        } else if entries.count == 1 {
            self.performSegue(withIdentifier: "Show Roster Person", sender: entries[0])
        } else {
            self.performSegue(withIdentifier: "Show Roster List", sender: entries)
        }
        
    }
    
    func nameToUseForDisplay(_ roster: CourseRoster) -> String {
        if let displayName = roster.name {
            return displayName
        } else if let firstName = roster.firstName, let lastName = roster.lastName {
            var components = PersonNameComponents()
            components.givenName = firstName
            components.familyName = lastName
            return PersonNameComponentsFormatter.localizedString(from: components, style: .default)
        } else if let firstName = roster.firstName {
            return firstName
        } else if let lastName = roster.lastName {
            return lastName
        } else {
            return ""
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let roster = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "Course Roster Cell", for: indexPath) as UITableViewCell
        
        let label = cell.viewWithTag(1) as! UILabel
        label.text = self.nameToUseForDisplay(roster)
        
        if ConfigurationManager.doesMobileServerSupportVersion("4.5") {
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .blue
        } else {
            if let _ = AppGroupUtilities.userDefaults()?.string(forKey: "urls-directory-studentSearch") {
                cell.isUserInteractionEnabled = true
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .blue
            } else {
                cell.isUserInteractionEnabled = false
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        }
        
        return cell
        
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type{
        case NSFetchedResultsChangeType.insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .none)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Roster List" {
            let detailController = segue.destination as! DirectoryViewController
            detailController.entries = sender as! [DirectoryEntry];
            detailController.module = self.module;
        } else if segue.identifier == "Show Roster Person" {
            let detailController = segue.destination as! DirectoryEntryViewController
            detailController.entry = sender as? DirectoryEntry;
            detailController.module = self.module;
        }
    }
    
    
    func fetchRoster(_ sender: AnyObject) {
        
        
        if let userid = CurrentUser.sharedInstance.userid {
            let urlBase = self.module?.property(forKey: "roster")
            let escapedUserId = userid.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let escapedTermId = self.termId?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let escapedSectionId = self.sectionId?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let urlString = "\(urlBase!)/\(escapedUserId!)?term=\(escapedTermId!)&section=\(escapedSectionId!)"
            
            if self.fetchedResultsController.fetchedObjects!.count <= 0 {
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
                hud.label.text = loadingString
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
            }
            
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.parent = self.module!.managedObjectContext
            privateContext.undoManager = nil
            
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
                        
                        let request = NSFetchRequest<CourseRoster>(entityName: "CourseRoster")

                        request.predicate = NSPredicate(format: "termId == %@ && sectionId == %@", self.termId!, self.sectionId!)
                        let oldObjects = try! privateContext.fetch(request)
                        
                        for oldObject in oldObjects {
                            privateContext.delete(oldObject)
                        }
                        
                        for jsonDictionary in json["activeStudents"].array! {
                            
                            let entry = NSEntityDescription.insertNewObject(forEntityName: "CourseRoster", into: privateContext) as! CourseRoster
                            entry.termId = self.termId;
                            entry.sectionId = self.sectionId;
                            entry.studentId = jsonDictionary["id"].string
                            entry.name = jsonDictionary["name"].string
                            entry.firstName = jsonDictionary["firstName"].string
                            if let middleName = jsonDictionary["middleName"].string {
                                entry.middleName = middleName
                            }
                            entry.lastName = jsonDictionary["lastName"].string
                            if let photo = jsonDictionary["photo"].string {
                                entry.photo = photo
                            }
                            entry.sectionKey = "\(entry.lastName.first!)"
                        }
                        
                        try privateContext.save()
                        
                        privateContext.parent?.perform({
                            do {
                                try privateContext.parent?.save()
                            } catch let error {
                                print (error)
                            }
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
        let label = UILabel(frame: CGRect(x: 8,y: 0,width: tableView.frame.width, height: 30))
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.text = fetchedResultsController.sections![section].name
        
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
}
