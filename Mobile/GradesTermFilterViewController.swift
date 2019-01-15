//
//  GradesTermFilterViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 9/10/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class GradesTermFilterViewController : UITableViewController {
    
    var module : Module?
    var delegate : GradesTermSelectorDelegate?
    var terms : [GradeTerm]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
        let request = NSFetchRequest<GradeTerm>(entityName: "GradeTerm")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        terms = try? managedObjectContext.fetch(request)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendView("Grades Term Filter", moduleName: self.module?.name)
    }
    
    //MARK :UITable
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let terms = terms {
            return terms.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let _ = self.delegate {
            self.delegate!.term = terms![(indexPath as NSIndexPath).row]
            self.dismiss(animated: true, completion: nil)

        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Term Cell", for: indexPath) as UITableViewCell
        
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.accessibilityHint = NSLocalizedString("Selects a term.", comment: "VoiceOver hint for button that selects a term")
        
        let term = terms![(indexPath as NSIndexPath).row]
        
        let titleLabel = cell.viewWithTag(1) as! UILabel
        
        titleLabel.text = term.name
        return cell
    }
}
