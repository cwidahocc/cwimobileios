//
//  DirectoryViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 12/2/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import Contacts

class DirectoryViewController : UITableViewController, UISearchBarDelegate, DirectoryFilterDelegate, EllucianMobileLaunchableControllerProtocol {
    
    let searchDelayInterval : TimeInterval = 0.5
    
    @IBOutlet var searchBar: UISearchBar!
    var module : Module!
    var hideStudents : Bool?
    var hideFaculty : Bool?
    
    var forcedFilteredGroup : String?
    var searchDelayer : Timer?
    var legacySearch = false
    var hiddenGroups = [String]()
    
    @IBOutlet var filterButton: UIBarButtonItem!
    var tableData = [[DirectoryEntry]]()
    var entries = [DirectoryEntry]()
    var data : NSMutableData?
    var groups = [DirectoryDefinitionProtocol]()
    var inSearch = false
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask : URLSessionDataTask?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if entries.count > 0 {
            //coming from another source, such as course roster
            inSearch = true
            buildTableData(self.entries)
        }
        
        buildGroups()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 53
        
        self.title = self.module?.name
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            self.splitViewController?.preferredDisplayMode = .allVisible;
        } else {
            self.splitViewController?.preferredDisplayMode = .automatic;
        }
        
        if groups.count <= 1 {
            filterButton.isEnabled = false;
            self.navigationController?.navigationBar.topItem!.rightBarButtonItem = nil;
        }
        
        if let searchBar = searchBar {
            searchBar.becomeFirstResponder()
        }
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(DirectoryViewController.signInHappened), name: CurrentUser.LoginExecutorSuccessNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendView("Directory page", moduleName: self.module?.name)
        
    }
    
    @objc func doDelayedSearch(_ timer: Timer) {
        searchDelayer = nil
        doSearch()
    }
    
    func doSearch() {
        MBProgressHUD.hide(for: self.view, animated: true)
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
        hud.label.text = loadingString
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        
        if !self.legacySearch {
            doModernSearch()
        } else {
            doLegacySearch()
        }
    }
    
    func doLegacySearch() {
        if let searchString = self.searchBar.text {
            if !searchString.isEmpty {
                var url: String? = nil
                if let module = module , self.module?.type == "directory" {
                    
                    let groupsInUse = self.groups.filter() {
                        !self.hiddenGroups.contains($0.internalName!)
                    }
                    let filteredGroups = groupsInUse.map() {
                        $0.internalName!
                    }
                    
                    if filteredGroups.count == 0 {
                        clear()
                        return
                    } else if filteredGroups.count == 2 {
                        url = module.property(forKey: "allSearch")
                    } else if filteredGroups.count == 1 && filteredGroups.contains("student") {
                        url = module.property(forKey: "studentSearch")
                    } else if filteredGroups.count == 1 && filteredGroups.contains("faculty") {
                        url = module.property(forKey: "facultySearch")
                    }
                }
                
                let encodedSearchString = searchString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                url = "\(url!)?searchString=\(encodedSearchString!)"
                
                var request = URLRequest(url: URL(string: url!)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
                if (LoginExecutor.isUsingBasicAuthentication()) {
                    request.addAuthenticationHeader()
                }
                executeSearch(request)
            }
        } else {
            clear()
        }
    }
    
    func doModernSearch() {
        if let searchString = self.searchBar.text {
            if !searchString.isEmpty {
                var url = module?.property(forKey: "baseSearch")
                
                var groupsInUse = self.groups
                if self.hiddenGroups.count > 0 {
                    groupsInUse = self.groups.filter() {
                        !self.hiddenGroups.contains($0.internalName!)
                    }
                }
                
                let filteredGroups = groupsInUse.map() {
                    return $0.internalName!
                    } as [String]
                
                if filteredGroups.count > 0 {
                    let modifiedSearchString = searchString.replacingOccurrences(of: "\u{2018}", with: "\u{27}").replacingOccurrences(of: "\u{2019}", with: "\u{27}")
                    let encodedSearchString = modifiedSearchString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                    let encodedDirectories = filteredGroups.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                    url = "\(url!)?searchString=\(encodedSearchString!)&directories=\(encodedDirectories!)"
                    var request = URLRequest(url: URL(string: url!)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
                    if CurrentUser.sharedInstance.isLoggedIn {
                        request.addAuthenticationHeader()
                    }
                    executeSearch(request)
                } else {
                    clear()
                }
            }
        } else {
            clear()
        }
    }
    
    func clear() {
        inSearch = false
        self.entries = [DirectoryEntry]()
        if !self.splitViewController!.isCollapsed {
            self.performSegue(withIdentifier: "Empty Entry", sender: nil)
        }
        self.tableData = self.partitionObjects(self.entries, collationStringSelector: #selector(DirectoryEntry.nameToUseForLastNameSort))
        self.tableView.reloadData()
    }
    
    // MARK: UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let searchDelayer = searchDelayer {
            searchDelayer.invalidate()
        }
        if !searchText.isEmpty {
            searchDelayer = Timer.scheduledTimer(timeInterval: searchDelayInterval, target: self, selector: #selector(DirectoryViewController.doDelayedSearch(_:)), userInfo: searchText, repeats: false)
            inSearch = true
        } else {
            clear()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchDelayer = nil
        doSearch()
    }
    
    //MARK: segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Filter" {
            self.sendEvent(category: .ui_Action, action: .button_Press, label: "Select directory type", moduleName: self.module?.name)
            let navigationController = segue.destination as! UINavigationController
            let detailController = navigationController.viewControllers[0] as! DirectoryFilterViewController
            detailController.module = self.module
            detailController.hiddenGroups = self.hiddenGroups
            detailController.groups = self.groups
            detailController.delegate = self
        } else if segue.identifier == "Show Directory Profile" {
            let detailController : DirectoryEntryViewController
            if segue.destination is DirectoryEntryViewController {
                detailController = segue.destination as! DirectoryEntryViewController
            } else {
                let navigationController = segue.destination as! UINavigationController
                detailController = navigationController.viewControllers[0] as! DirectoryEntryViewController
            }
            detailController.entry = sender as? DirectoryEntry;
            detailController.module = self.module;
        }
    }
    
    //MARK: other
    func partitionObjects(_ array: [DirectoryEntry], collationStringSelector selector: Selector) -> [[DirectoryEntry]] {
        let collation: UILocalizedIndexedCollation = UILocalizedIndexedCollation.current()
        let sectionCount = collation.sectionTitles.count
        //section count is take from sectionTitles and not sectionIndexTitles
        var unsortedSections = [[DirectoryEntry]](repeating: [DirectoryEntry](), count: sectionCount)
        
        //put each object into a section
        for object in array {
            let index = collation.section(for: object, collationStringSelector: selector)
            unsortedSections[index].append(object)
        }
        var sections = [[DirectoryEntry]](repeating: [DirectoryEntry](), count: sectionCount)
        //sort each section
        for i in 0 ..< unsortedSections.count {
            let sorted = collation.sortedArray(from: unsortedSections[i], collationStringSelector: selector) as! [DirectoryEntry]
            sections[i] = sorted
        }
        
        return sections;
    }
    
    func connection(_ theConnection: NSURLConnection, didReceiveData incrementalData: Data) {
        if self.data == nil {
            self.data = NSMutableData(capacity: 2048)
        }
        self.data?.append(incrementalData)
        
    }
    
    func buildTableData(_ entries: [DirectoryEntry]) {
        
        switch CNContactsUserDefaults.shared().sortOrder {
        case .none, .userDefault, .familyName:
            self.tableData = self.partitionObjects(self.entries, collationStringSelector: #selector(DirectoryEntry.nameToUseForLastNameSort))
        case .givenName:
            self.tableData = self.partitionObjects(self.entries, collationStringSelector: #selector(DirectoryEntry.nameToUseForFirstNameSort))
        }
        
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            var count = 0
            if inSearch {
                if entries.count == 0 {
                    count += 1
                } else {
                    if let searchBar = searchBar, let searchText = searchBar.text, searchText.isEmpty {
                        count += 1
                    }
                }
            }
            if !inSearch {
                count += 1
            }
            if !CurrentUser.sharedInstance.isLoggedIn {
                count += 1
            }
            return count
        }
        if entries.count > 0 {
            return tableData[section-1].count
        }
        return 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return UILocalizedIndexedCollation.current().sectionTitles.count + 1
    }
    
    var badImages = [String]()
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == 0 {
            switch ((indexPath as NSIndexPath).row, CurrentUser.sharedInstance.isLoggedIn, inSearch, entries.count == 0) {
            case (0, true, false, _), (0, false, false, _):
                return tableView.dequeueReusableCell(withIdentifier: "Directory Initial Message Cell", for: indexPath) as UITableViewCell
            case (0, false, true, _), (1, false, false, _):
                return tableView.dequeueReusableCell(withIdentifier: "Directory Sign In Message Cell", for: indexPath) as UITableViewCell
            case (0, true, true, true), (1, false, true, true):
                return tableView.dequeueReusableCell(withIdentifier: "Directory Empty Message Cell", for: indexPath) as UITableViewCell
            default:
                return UITableViewCell()
            }
        } else if (indexPath.section-1) < self.tableData.count && indexPath.row < self.tableData[indexPath.section-1].count {
            let entry = self.tableData[(indexPath as NSIndexPath).section-1][(indexPath as NSIndexPath).row]
            let cell : UITableViewCell
            if let logo = entry.imageUrl , logo != "" {
                if badImages.contains(logo) {
                    cell  = tableView.dequeueReusableCell(withIdentifier: "Directory Name Cell", for: indexPath) as UITableViewCell
                } else {
                    cell  = tableView.dequeueReusableCell(withIdentifier: "Directory Name Image Cell", for: indexPath) as UITableViewCell
                    let imageView = cell.viewWithTag(3) as! UIImageView
                    imageView.loadImagefromURL(logo, successHandler: {
                         DispatchQueue.main.async {
                            imageView.isHidden = false
                            imageView.convertToCircleImage()
                        }
                        }, failureHandler:  {
                            DispatchQueue.main.async {
                                () -> Void in
                                //still the image in the cell we care about?
                                let desiredSection = (indexPath).section-1
                                if desiredSection < self.tableData.count {
                                    let sectionData = self.tableData[desiredSection]
                                    let desiredRow = (indexPath as NSIndexPath).row
                                    
                                    if desiredRow < sectionData.count {
                                        let currentEntry = sectionData[desiredRow]
                                        if entry == currentEntry {
                                            
                                            imageView.isHidden = true
                                            self.badImages.append(logo)
                                            self.tableView.reloadRows(at: [indexPath], with: .none)
                                        }
                                    }
                                }
                            }
                            
                            
                        }
                    )
                }
            } else {
                cell  = tableView.dequeueReusableCell(withIdentifier: "Directory Name Cell", for: indexPath) as UITableViewCell
            }
            
            let nameLabel = cell.viewWithTag(1) as! UILabel
            let typeLabel = cell.viewWithTag(2) as! UILabel
            nameLabel.text = entry.nameToUseForDisplay()
            typeLabel.text = formatType(entry)
            return cell
        }
        return UITableViewCell()
    }
    
    func formatType(_ entry: DirectoryEntry) -> String? {
        if let type = entry.type {
            if !legacySearch {
                return type
            } else {
                switch type {
                case "student": return NSLocalizedString("Students", comment: "student search scope in directory")
                case "faculty": return NSLocalizedString("Faculty/Staff", comment:"facilty/staff search scope in directory")
                default: return type
                    
                }
            }
            
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return (indexPath as NSIndexPath).section == 0 ? nil : indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = self.tableData[(indexPath as NSIndexPath).section-1][(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: "Show Directory Profile", sender: entry)
    }
    
    func updateFilter(_ filter: [String]) {
        if !self.splitViewController!.isCollapsed {
            self.performSegue(withIdentifier: "Empty Entry", sender: nil)
        }
        self.hiddenGroups = filter
        if groups.count == filter.count {
            clear()
        } else if let searchString = self.searchBar.text, !searchString.isEmpty {
            doSearch()
        }
    }
    
    @objc func signInHappened() {
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    func buildGroups () {
        
        
        let moduleKey = "\(module!.internalKey!)-hiddenGroups"
        if let hiddenGroups = AppGroupUtilities.userDefaults()?.array(forKey: moduleKey) as? [String] {
            self.hiddenGroups = hiddenGroups
        } else {
            self.hiddenGroups = [String]()
        }
        
        do {
            let fetchRequest = NSFetchRequest<DirectoryDefinition>(entityName: "DirectoryDefinition")
            fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "displayName", ascending: true)]
            
            if let groups = try self.module!.managedObjectContext?.fetch(fetchRequest) , groups.count > 0 && module?.property(forKey: "directories") != nil {
                let supportedDirectories = module?.property(forKey: "directories")?.components(separatedBy: ",")
                let moduleGroups = groups.filter() {
                    supportedDirectories!.contains($0.key!)
                }
                self.groups = moduleGroups
            } else {
                legacySearch = true
                if self.module?.property(forKey: "student") == "true" && self.module?.property(forKey: "faculty") == "true" {
                    self.groups = [ legacyStudentDefinition(), legacyFacultyDefinition() ]
                } else if self.module?.property(forKey: "student") == "true" {
                    self.groups = [ legacyStudentDefinition() ]
                } else if self.module?.property(forKey: "faculty") == "true" {
                    self.groups = [ legacyFacultyDefinition() ]
                } else {
                    self.groups = [ legacyStudentDefinition(), legacyFacultyDefinition() ]
                }
                self.groups = self.groups.sorted( by: { $0.displayName! < $1.displayName!})
            }
        } catch {
        }
    }
    
    func legacyStudentDefinition() -> DirectoryDefinitionProtocol {
        let dir = DirectoryUnmanagedDefinition()
        dir.internalName = "student"
        dir.displayName = NSLocalizedString("Students", comment: "student search scope in directory")
        dir.authenticatedOnly = true
        return dir
    }
    
    func legacyFacultyDefinition() -> DirectoryDefinitionProtocol {
        let dir = DirectoryUnmanagedDefinition()
        dir.internalName = "faculty"
        dir.displayName = NSLocalizedString("Faculty/Staff", comment:"facilty/staff search scope in directory")
        dir.authenticatedOnly = true
        return dir
    }
    
    private func executeSearch(_ request: URLRequest) {
        dataTask = defaultSession.dataTask(with: request) {
            data, response, error in
            if self.inSearch {
                if let data = data {
                    self.entries = DirectoryEntry.parseResponse(data)
                    self.buildTableData(self.entries)
                } else {
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment:"title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment:"message when data cannot load due to a poor netwrok connection"), preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: UIAlertActionStyle.default)
                        alertController.addAction(alertAction)
                        self.present(alertController, animated: true)
                    }
                }
            }
            
            DispatchQueue.main.async(execute: {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                MBProgressHUD.hide(for: self.view, animated: true)
            })
        }
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        dataTask?.resume()
    }
}
