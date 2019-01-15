//
//  DirectoryFilterViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 12/3/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

protocol DirectoryFilterDelegate : class {
    func updateFilter(_ hiddenGroups: [String])
}


class DirectoryFilterViewController : UITableViewController {
    var hiddenGroups = [String]()
    weak var delegate : DirectoryFilterDelegate?
    var module : Module?
    var groups = [DirectoryDefinitionProtocol]()
    


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Directory Filter Cell", for: indexPath) as UITableViewCell

        let definition = groups[(indexPath as NSIndexPath).row]
        
        let textLabel = cell.viewWithTag(1) as! UILabel
        textLabel.text = definition.displayName
        if hiddenGroups.contains(definition.internalName!) {
            cell.accessoryType = UITableViewCellAccessoryType.none
        } else {
            cell.accessoryType = .checkmark
        }
        let lockImageView = cell.viewWithTag(2) as! UIImageView
        
        if CurrentUser.sharedInstance.isLoggedIn {
            lockImageView.isHidden = true
        } else {
            lockImageView.isHidden = !definition.authenticatedOnly
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let definition = groups[(indexPath as NSIndexPath).row]
        let cell = tableView.cellForRow(at: indexPath)
        
        if cell?.accessoryType == .checkmark {
            cell?.accessoryType = .none
            self.hiddenGroups.append(definition.internalName!)
        } else {
            cell?.accessoryType = .checkmark
            if let index = self.hiddenGroups.index(of: definition.internalName!) {
                self.hiddenGroups.remove(at: index)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.updateCategories()
    }
    
    func updateCategories() {
        let moduleKey = "\(module!.internalKey!)-hiddenGroups"
        
        let savedGroups = AppGroupUtilities.userDefaults()?.array(forKey: moduleKey)

        if savedGroups == nil || savedGroups as! [String] != hiddenGroups {
            sendEventToTracker1(category: .ui_Action, action: .list_Select, label: "Filter changed", moduleName: self.module?.name)

        }
        AppGroupUtilities.userDefaults()?.set(hiddenGroups, forKey: moduleKey)

        self.delegate?.updateFilter(hiddenGroups)
    }
    
    @IBAction func dismiss(_ sender: AnyObject) {
        updateCategories()
        self.dismiss(animated: true, completion: nil)
    }
}
