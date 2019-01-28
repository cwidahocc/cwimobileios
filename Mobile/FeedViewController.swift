//
//  FeedViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 7/29/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class FeedViewController : UITableViewController, UISearchResultsUpdating , NSFetchedResultsControllerDelegate, FeedFilterDelegate, EllucianMobileLaunchableControllerProtocol {
    
    
    @IBOutlet var filterButton: UIBarButtonItem!
    
    let searchController = UISearchController(searchResultsController: nil)
    var module : Module!
    
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
    var feedModule : FeedModule?
    var hiddenCategories = NSMutableSet()
    var searchString : String?
    var thumbnailCache = [String: UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.module?.name
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        buildSearchBar()
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            self.splitViewController?.preferredDisplayMode = .allVisible;
        } else {
            self.splitViewController?.preferredDisplayMode = .automatic;
        }
        
        // Recieve notification to ensure that FeedViewController searchController resets
        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewController.detailViewWillAppear(_:)), name: FeedDetailViewController.feedDetailNotification, object: nil)
        
        fetchFeeds()
        reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendView("News List", moduleName: self.module?.name)
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
        self.sendEventToTracker1(category: .ui_Action, action: .search, label:"Search", moduleName:self.module?.name);
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
    func fetchFeeds() {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.module?.managedObjectContext
        privateContext.undoManager = nil
        
        let urlString = self.module?.property(forKey: "feed")
        
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
                
                var previousFeeds = [Feed]()
                var existingFeeds = [Feed]()
                var newKeys = [String]()
                
                let request = NSFetchRequest<Feed>(entityName: "Feed")
                request.predicate = NSPredicate(format:"module.name = %@", self.module!.name)
                let oldObjects = try privateContext
                    .fetch(request)
                for feed in oldObjects {

                    if !feed.entryId.isEmpty {
                        previousFeeds.append(feed)
                    } else {
                        privateContext.delete(feed)
                    }
                }
                
                let moduleRequest = NSFetchRequest<FeedModule>(entityName: "FeedModule")
                moduleRequest.predicate = NSPredicate(format: "name = %@", self.module!.name)
                let feedModules = try privateContext.fetch(moduleRequest)
                let feedModule : FeedModule
                if feedModules.count > 0 {
                    feedModule = feedModules.last!
                } else {
                    feedModule = NSEntityDescription.insertNewObject(forEntityName: "FeedModule", into: privateContext) as! FeedModule
                    feedModule.name = self.module?.name
                }
                
                let categoryRequest = NSFetchRequest<FeedCategory>(entityName: "FeedCategory")
                categoryRequest.predicate = NSPredicate(format: "moduleName = %@", self.module!.name)
                let categoryArray = try privateContext.fetch(categoryRequest)
                var categoryMap = [String: FeedCategory]()
                for feedCategory in categoryArray {
                    categoryMap[feedCategory.name] = feedCategory
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                for entry in json["entries"].array! {
                    let uid = entry["entryId"].string;
                    
                    let filteredArray = previousFeeds.filter({
                        let feed = $0 as Feed
                        return feed.entryId == uid;
                    })
                    if filteredArray.count > 0 {
                        existingFeeds.append(filteredArray[0])
                    } else {
                        let feed = NSEntityDescription.insertNewObject(forEntityName: "Feed", into: privateContext) as! Feed
                        feed.module = feedModule
                        feedModule.addFeedsObject(feed)
                        
                        newKeys.append(uid!)
                        
                        feed.entryId = entry["entryId"].string
                        let postDate = entry["postDate"].string!
                        feed.postDateTime = dateFormatter.date(from: postDate)
                        feed.dateLabel = self.datetimeOutputFormatter.string(from: feed.postDateTime)
                        if entry["link"] != nil {
                            if let links = entry["link"].array , links.count > 0 {
                                feed.link = links[0].string
                            }
                        }
                        if entry["title"] != nil {
                            if let title = entry["title"].string , title != "" {
                                feed.title = title
                            }
                        }
                        if entry["content"] != nil {
                            if let content = entry["content"].string , content != "" {
                                feed.content = content
                            }
                        }
                        if entry["logo"] != nil {
                            if let logo = entry["logo"].string , logo != "" {
                                feed.logo = logo
                            }
                        }
                        
                        let categoryLabel = entry["feedName"].string
                        var category = categoryMap[categoryLabel!]
                        if category == nil {
                            category = NSEntityDescription.insertNewObject(forEntityName: "FeedCategory", into: privateContext) as? FeedCategory
                            category!.name = categoryLabel
                            category!.moduleName = self.module?.name
                            categoryMap[categoryLabel!] = category
                        }
                        feed.addCategoryObject(category)
                        category!.addFeedObject(feed)
                        
                    }
                }
                
                try privateContext.save()
                for oldObject in previousFeeds {
                    if !existingFeeds.contains(oldObject) {
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
                    self.readFeedModule()
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
        if segue.identifier == "Show Feed Filter" {
            self.sendEvent(category: .ui_Action, action: .list_Select, label: "Select filter", moduleName: self.module?.name)
            let navigationController = segue.destination as! UINavigationController
            let detailController = navigationController.viewControllers[0] as! FeedFilterViewController
            detailController.feedModule = self.feedModule
            detailController.hiddenCategories = self.hiddenCategories
            detailController.module = self.module
            detailController.delegate = self
        } else if segue.identifier == "Show Detail" || segue.identifier == "Show Detail with Image" {
            let detailController = (segue.destination as! UINavigationController).topViewController as! FeedDetailViewController
            let feed = fetchedResultsController.object(at: self.tableView.indexPathForSelectedRow!)
            detailController.feed = feed
            detailController.module = self.module
        }
    }
    
    //MARK read
    func readFeedModule() {
        let request = NSFetchRequest<FeedModule>(entityName: "FeedModule")
        request.predicate = NSPredicate(format: "name = %@", self.module!.name)
        request.fetchLimit = 1
        do {
            let results = try self.module!.managedObjectContext!.fetch(request)
            if results.count > 0 {
                self.feedModule = results[0]
                let hiddenCategories = self.feedModule?.hiddenCategories
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
    
    //MARK: FeedFilterDelegate
    func reloadData() {
        self.readFeedModule()
        _fetchedResultsController = nil
        do {
            try self.fetchedResultsController.performFetch()
        } catch { }
        self.tableView.reloadData()
    }
    
    // MARK: fetch
    var fetchedResultsController: NSFetchedResultsController<Feed> {
        // return if already initialized
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
        
        let request = NSFetchRequest<Feed>(entityName: "Feed")
        
        var subPredicates = [NSPredicate]()
        
        subPredicates.append( NSPredicate(format: "module.name = %@", self.module!.name) )
        
        if let searchString = self.searchController.searchBar.text , !searchString.isEmpty {
            subPredicates.append( NSPredicate(format: "((title CONTAINS[cd] %@) OR (content CONTAINS[cd] %@))", searchString, searchString) )
        }
        
        if self.hiddenCategories.count > 0 {
            subPredicates.append( NSPredicate(format: "NONE category.name IN %@",  self.hiddenCategories) )
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
        
        request.sortDescriptors = [NSSortDescriptor(key: "dateLabel", ascending: false),NSSortDescriptor(key: "postDateTime", ascending: false),NSSortDescriptor(key: "title", ascending: true)]
        
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
    var _fetchedResultsController: NSFetchedResultsController<Feed>?
    
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
        let cell : UITableViewCell
        let feed = fetchedResultsController.object(at: indexPath)
        
        
        if let logo = feed.logo , logo != "" {
            cell  = tableView.dequeueReusableCell(withIdentifier: "Feed Image Cell", for: indexPath) as UITableViewCell
            let imageView = cell.viewWithTag(5) as! UIImageView
            
            if let image = thumbnailCache[logo] {
                imageView.image = image
                // imageView.convertToCircleImage()
                
            } else {
                imageView.image = nil
                
                DispatchQueue.global(qos: .userInteractive).async {
                    let imageData = try? Data(contentsOf: URL(string: logo)!)
                    
                    if let imageData = imageData {
                        if let image = UIImage(data: imageData) {
                            
                            self.thumbnailCache[logo] = image
                            DispatchQueue.main.async {
                                imageView.image = image
                                // imageView.convertToCircleImage()
                            }
                        }
                    }
                }
            }
            
            
        } else {
            cell  = tableView.dequeueReusableCell(withIdentifier: "Feed Cell", for: indexPath) as UITableViewCell
            
        }
        
        
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let dateLabel = cell.viewWithTag(2) as! UILabel
        let categoryLabel = cell.viewWithTag(3) as! UILabel
        let contentLabel = cell.viewWithTag(4) as! UILabel
        
        titleLabel.preferredMaxLayoutWidth = titleLabel.frame.width
        dateLabel.preferredMaxLayoutWidth = dateLabel.frame.width
        categoryLabel.preferredMaxLayoutWidth = categoryLabel.frame.width
        contentLabel.preferredMaxLayoutWidth = contentLabel.frame.width
        titleLabel.text = feed.title.convertingHTMLToPlainText()
        dateLabel.text = feed.postDateTime.timeAgo
        
        //Changed for iOS 11 & 12 - version 5.3 
        let categoriesArray = (feed.category as NSSet).map { (m) -> String in
            
            let category = m as! FeedCategory
            
            return category.name
        }
        
        /*
         let categoriesArray = feed.category.map{ m -> String in
         let category = m as! FeedCategory
         return category.name
         }
         */
        
        let categories = categoriesArray.joined(separator: ", ")
        categoryLabel.text = categories
        contentLabel.text = feed.content?.convertingHTMLToPlainText()
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
