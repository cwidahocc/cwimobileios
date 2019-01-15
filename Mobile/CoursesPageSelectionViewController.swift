//
//  CoursesPageSelectionViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 10/15/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

protocol ScheduleTermSelectedDelegate : class {
    var selectedTerm : Int { get set }
    func loadSchedule()
}


class CoursesPageSelectionViewController : UITableViewController {
    var terms : [CourseTerm]?
    var coursesChangePageDelegate : ScheduleTermSelectedDelegate?
    var module : Module?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendView("Term List", moduleName: self.module?.name)
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
        if let delegate = self.coursesChangePageDelegate {
            delegate.selectedTerm = (indexPath as NSIndexPath).row
            delegate.loadSchedule()
            self.dismiss(animated: true, completion: nil)
            
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Courses Term Selection Cell", for: indexPath) as UITableViewCell
        
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.accessibilityHint = NSLocalizedString("Selects a term.", comment: "VoiceOver hint for button that selects a term")
        
        let term = terms![(indexPath as NSIndexPath).row]
        
        let titleLabel = cell.viewWithTag(1) as? UILabel
        
        titleLabel!.text = term.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
