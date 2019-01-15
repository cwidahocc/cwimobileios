//
//  FeedFilterViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 7/31/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

protocol FeedFilterDelegate : class {
    func reloadData()
}

class FeedFilterViewController : UITableViewController {
    
    var startingHiddenCategories : NSMutableSet?
    var categories = [String]()
    
    var feedModule : FeedModule?
    var hiddenCategories : NSMutableSet?
    var module : Module?
    weak var delegate : FeedFilterDelegate?
    
    override func viewDidLoad() {
        self.startingHiddenCategories = self.hiddenCategories
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.initializeCategories()
    }
    
    //MARK table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Feed Filter Cell", for: indexPath) as UITableViewCell
        
        let category = self.categories[indexPath.row]        
        let textLabel = cell.viewWithTag(1) as! UILabel
        textLabel.text = category
        if (self.hiddenCategories!.contains(category) ) {
            cell.accessoryType = UITableViewCellAccessoryType.none
        } else {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let textLabel = cell?.viewWithTag(1) as! UILabel
        
        if cell?.accessoryType == .checkmark {
            cell?.accessoryType = .none
            self.hiddenCategories?.add(textLabel.text!)
        } else {
            cell?.accessoryType = .checkmark
            //self.hiddenCategories = self.hiddenCategories!.filter() { $0 as? String != textLabel.text }
            self.hiddenCategories?.remove(textLabel.text!)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.updateCategories()
        self.delegate?.reloadData()
    }
    
    func updateCategories() {
        if hiddenCategories!.count > 0 {
            self.feedModule?.hiddenCategories = (hiddenCategories!.allObjects as! [String]).joined(separator: ",")
        } else {
            self.feedModule?.hiddenCategories = nil
        }
        
        if self.startingHiddenCategories!.isEqual(self.hiddenCategories) {
            sendEventToTracker1(category: .ui_Action, action: .list_Select, label: "Filter changed", moduleName: self.module?.name)
        }
        do {
            try feedModule?.managedObjectContext?.save()
        } catch {
            
        }
    }
    
    @IBAction func dismiss(_ sender: AnyObject) {
        updateCategories()
        self.dismiss(animated: true, completion: nil)
    }
    func initializeCategories() {

        do {
            let request = NSFetchRequest<FeedCategory>(entityName: "FeedCategory")
            request.predicate = NSPredicate(format: "moduleName = %@", self.module!.name)
            let results = try self.module!.managedObjectContext!.fetch(request)
            let categories = results.map {
                    return $0.name!
            }
            self.categories = categories.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
        } catch {
            
        }
    }
}
