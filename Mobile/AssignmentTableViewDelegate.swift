//
//  AssignmentTableViewDelegate.swift
//  Mobile
//
//  Created by Alan McEwan on 1/20/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import UIKit


class AssignmentTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate
{
    var assignmentTableView: UITableView!
    var assignmentController: NSFetchedResultsController<CourseAssignment>?
    var myDatetimeOutputFormatter: DateFormatter?
    var assignmentTableHeightConstraint: NSLayoutConstraint!
    var assignmentTableWidthConstraint: NSLayoutConstraint!
    var module: Module!
    var myViewController:ILPViewController!
    var myNoDataView:UIView?
    var overdueRed:UIColor?
    var todayGreen:UIColor?
    var lightGray:UIColor?
    
    init(tableView: UITableView, resultsController: NSFetchedResultsController<CourseAssignment>, heightConstraint: NSLayoutConstraint, widthConstraint: NSLayoutConstraint, parentModule:Module, viewController: ILPViewController) {
        
        assignmentTableView = tableView
        assignmentController = resultsController
        assignmentTableHeightConstraint = heightConstraint
        assignmentTableWidthConstraint = widthConstraint
        module = parentModule
        myViewController = viewController
        
        super.init()
        
        assignmentTableView.delegate = self;
        assignmentTableView.dataSource = self;
        assignmentController!.delegate = self;
        
        overdueRed = UIColor(red: 193.0/255.0, green: 39.0/255.0, blue: 45.0/255.0, alpha: 1.0)
        todayGreen = UIColor(red: 55.0/255.0, green: 105.0/255.0, blue: 55.0/255.0, alpha: 1.0)
        lightGray = UIColor(red: 229.0/255.0, green: 229.0/255.0, blue: 229.0/255.0, alpha: 1.0)
    }
    
    /* called first
    begins update to `UITableView`
    ensures all updates are animated simultaneously */
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        assignmentTableView.beginUpdates()
    }

    /* helper method to configure a `UITableViewCell`
    ask `NSFetchedResultsController` for the model */
    func configureCell(_ cell: UITableViewCell,
        atIndexPath indexPath: IndexPath) {
            
            let assignment = assignmentController!.object(at: indexPath)
            let nameLabel = cell.viewWithTag(100) as! UILabel
            if assignment.name != nil {
                nameLabel.text = assignment.name
            }
            
            let sectionName = self.tableView(assignmentTableView, titleForHeaderInSection: (indexPath as NSIndexPath).section)
            
            if sectionName == NSLocalizedString("OVERDUE", comment:"overdue assignment indicator for ilp module") {
                nameLabel.textColor = overdueRed
            }
            
            let dueDateLabel = cell.viewWithTag(101) as! UILabel
            
            if assignment.dueDate != nil {
                if let assignmentDate = assignment.dueDate {
                    dueDateLabel.text = self.datetimeOutputFormatter()!.string(from: assignmentDate)
                } else {
                    dueDateLabel.text = ""
                }
            } else {
                dueDateLabel.text = ""
            }
            
            if assignment.courseName != nil && assignment.courseSectionNumber != nil {
                let sectionNameLabel = cell.viewWithTag(102) as! UILabel
                sectionNameLabel.text = assignment.courseName + "-" + assignment.courseSectionNumber
            }
    }
    
    
    /* called:
    - when a new model is created
    - when an existing model is updated
    - when an existing model is deleted */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange object: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?)  {
            
            switch type {
            case .insert:
                assignmentTableView.insertRows(at: [newIndexPath as IndexPath!], with: .fade)
            case .update:
                let cell = self.assignmentTableView.cellForRow(at: indexPath as IndexPath!)
                configureCell(cell!, atIndexPath: indexPath as IndexPath!)
                assignmentTableView.reloadRows(at: [indexPath as IndexPath!], with: .fade)
            case .delete:
                assignmentTableView.deleteRows(at: [indexPath as IndexPath!], with: .fade)
            default:
                break
            }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType)
    {
        switch(type) {
            
        case .insert:
            assignmentTableView.insertSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
            
        case .delete:
            assignmentTableView.deleteSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
            
        default:
            break
        }
    }
    
    /* called last
    tells `UITableView` updates are complete */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        var totalRowHeight:CGFloat = 0.0
        
        for section in assignmentController!.sections! {
            if section.name  == NSLocalizedString("DUE TODAY", comment:"assignment due today indicator for ilp module") {
                totalRowHeight +=  CGFloat(section.numberOfObjects) * 50.0
            } else if section.name == NSLocalizedString("OVERDUE", comment:"overdue assignment indicator for ilp module"){
                totalRowHeight +=  CGFloat(section.numberOfObjects) * 50.0
            }
        }

        assignmentTableHeightConstraint.constant = totalRowHeight + (CGFloat(assignmentController!.sections!.count) * 30.0) + 50.0
        assignmentTableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Daily Assignment Cell", for: indexPath) as UITableViewCell
        cell.accessibilityTraits = UIAccessibilityTraitButton
        configureCell(cell, atIndexPath:indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50.0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView(frame: CGRect(x:0,y:0, width:assignmentTableWidthConstraint.constant, height:30.0))
        

        let constrainedView = UIView()
        constrainedView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(constrainedView)
        
        headerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[constrainedView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["constrainedView":constrainedView]))
        headerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[constrainedView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["constrainedView":constrainedView]))
        
        
        
        let title = UILabel(frame:CGRect(x:0,y:0,width:assignmentTableWidthConstraint.constant, height:30.0))
        title.font = UIFont.boldSystemFont(ofSize: 14)
        title.numberOfLines = 1;
        title.lineBreakMode = NSLineBreakMode.byTruncatingTail
        title.textAlignment = NSTextAlignment.left
        title.text = self.tableView(tableView, titleForHeaderInSection: section)
        
        if title.text == NSLocalizedString("OVERDUE", comment:"overdue assignment indicator for ilp module") {
            title.textColor = overdueRed
        } else {
            title.textColor = todayGreen
        }
        
        constrainedView.backgroundColor = lightGray
        title.backgroundColor = lightGray
        
        title.translatesAutoresizingMaskIntoConstraints = false
        constrainedView.addSubview(title)
        
        constrainedView.addConstraint(NSLayoutConstraint(item:title, attribute:NSLayoutAttribute.centerY, relatedBy:NSLayoutRelation.equal, toItem:constrainedView,
            attribute:NSLayoutAttribute.centerY, multiplier:1.0, constant:0.0))
        
        if title.text == NSLocalizedString("OVERDUE", comment:"overdue assignment indicator for ilp module") {
            let warningIcon:UIImage! = UIImage(named: "ilp-overdue-warning")
            let imageView = UIImageView(frame:CGRect(x:0.0, y:0.0, width:warningIcon.size.width, height:warningIcon.size.height))
            imageView.image = warningIcon
            imageView.translatesAutoresizingMaskIntoConstraints = false
            constrainedView.addSubview(imageView)
            
            constrainedView.addConstraint(NSLayoutConstraint(item:imageView, attribute:NSLayoutAttribute.centerY, relatedBy:NSLayoutRelation.equal, toItem:constrainedView, attribute:NSLayoutAttribute.centerY, multiplier:1.0, constant:0.0))
            constrainedView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-10-[warning]", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["warning" : imageView]))
            constrainedView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[warning]-10-[label]", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["warning":imageView, "label" : title]))
            constrainedView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[label]->=10-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["label" : title]))
        } else {
            constrainedView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-10-[label]-10-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["label" : title]))
        }
        
        return headerView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let numberOfSections = assignmentController!.sections?.count
        
        if numberOfSections == 0 {
            showNoDataView()
        } else {
            hideNoDataView()
        }
        
        return numberOfSections!
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRowsInSection = assignmentController!.sections?[section].numberOfObjects
        
        return numberOfRowsInSection!
    }
        
     func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = assignmentController!.sections {
            return sections[section].name
        } else {
            return "no name"
        }
    }
    
    func datetimeOutputFormatter() -> DateFormatter? {
        
        if (myDatetimeOutputFormatter == nil) {
            myDatetimeOutputFormatter = DateFormatter()
            myDatetimeOutputFormatter!.timeStyle = .short
            myDatetimeOutputFormatter!.dateStyle = .short
        }
        return myDatetimeOutputFormatter
    }
    
    func noDataView() ->UIView? {
        if myNoDataView == nil {
            myNoDataView = UIView(frame: CGRect(x:0,y:0, width:assignmentTableWidthConstraint.constant, height:40.0))
    
            let constrainedView = UIView()
            constrainedView.translatesAutoresizingMaskIntoConstraints = false
            myNoDataView?.addSubview(constrainedView)

            myNoDataView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[constrainedView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["constrainedView":constrainedView]))
            myNoDataView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[constrainedView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["constrainedView":constrainedView]))
            
            let noMatchesLabel = UILabel(frame:CGRect(x:0,y:0,width:assignmentTableWidthConstraint.constant, height:40.0))
            noMatchesLabel.font = UIFont.systemFont(ofSize: 14)
            noMatchesLabel.numberOfLines = 1;
            noMatchesLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
            noMatchesLabel.textAlignment = NSTextAlignment.left
            noMatchesLabel.text = NSLocalizedString("No assignments due today", comment:"no assignments due today message")
            
            constrainedView.backgroundColor = UIColor.white
            myNoDataView?.isHidden = true
            noMatchesLabel.translatesAutoresizingMaskIntoConstraints = false
            constrainedView.addSubview(noMatchesLabel)
            constrainedView.addConstraint(NSLayoutConstraint(item:noMatchesLabel,
                attribute:NSLayoutAttribute.centerY,
                relatedBy:NSLayoutRelation.equal,
                toItem:constrainedView,
                attribute:NSLayoutAttribute.centerY,
                multiplier:1.0,
                constant:0.0))
            constrainedView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-10-[label]-10-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["label" : noMatchesLabel]))
            
            assignmentTableView.insertSubview(myNoDataView!, belowSubview:assignmentTableView)
            assignmentTableHeightConstraint.constant = 90.0
        }
        return myNoDataView
    }
    
    func showNoDataView()
    {
        if ( myNoDataView == nil ) {
            myNoDataView = noDataView()
        }
        self.myNoDataView?.isHidden = false
    }
    
    func hideNoDataView()
    {
        self.myNoDataView?.isHidden = true
    }

}
