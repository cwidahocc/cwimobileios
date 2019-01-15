//
//  AnnouncementTableViewDelegate.swift
//  Mobile
//
//  Created by Alan McEwan on 1/20/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation


class AnnouncementTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate
{
    var announcementTableView: UITableView
    var announcementController: NSFetchedResultsController<CourseAnnouncement>?
    var myDatetimeOutputFormatter: DateFormatter?
    var announcementTableHeightConstraint: NSLayoutConstraint
    var announcementTableWidthConstraint: NSLayoutConstraint
    var module:Module!
    var myNoDataView:UIView?
    
    init(tableView: UITableView, controller: NSFetchedResultsController<CourseAnnouncement>, heightConstraint: NSLayoutConstraint, widthConstraint: NSLayoutConstraint, parentModule:Module) {
        
        announcementTableView = tableView
        announcementController = controller
        announcementTableHeightConstraint = heightConstraint
        announcementTableWidthConstraint = widthConstraint
        module = parentModule
        super.init()
        
        announcementTableView.delegate = self
        announcementTableView.dataSource = self
        
        announcementController!.delegate = self
    }
    
    /* called first
    begins update to `UITableView`
    ensures all updates are animated simultaneously */
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        announcementTableView.beginUpdates()
    }
    
    /* called:
    - when a new model is created
    - when an existing model is updated
    - when an existing model is deleted */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            
            switch type {
            case .insert:
                self.announcementTableView.insertRows(at: [newIndexPath as IndexPath!], with: .fade)
            case .update:
                let cell = self.announcementTableView.cellForRow(at: indexPath as IndexPath!)
                configureCell(cell!, atIndexPath: indexPath as IndexPath!)
                announcementTableView.reloadRows(at: [indexPath as IndexPath!], with: .fade)
            case .move:
                announcementTableView.deleteRows(at: [indexPath as IndexPath!], with: .fade)
                announcementTableView.insertRows(at: [newIndexPath as IndexPath!], with: .fade)
            case .delete:
                announcementTableView.deleteRows(at: [indexPath as IndexPath!], with: .fade)
            }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType)
    {
        switch(type) {
            
        case .insert:
            announcementTableView.insertSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
    
        case .delete:
            announcementTableView.deleteSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
            
        default:
            break
        }
    }

    /* called last
    tells `UITableView` updates are complete */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        announcementTableView.endUpdates()
        announcementTableHeightConstraint.constant = (CGFloat(announcementController!.fetchedObjects!.count) * 50.0) + 50.0
    }
    
    /* helper method to configure a `UITableViewCell`
    ask `NSFetchedResultsController` for the model */
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let announcement = announcementController!.object(at: indexPath)
        
        if announcement.title != nil {
            let nameLabel = cell.viewWithTag(100) as! UILabel
            nameLabel.text = announcement.title
        }
        
        if announcement.courseName != nil && announcement.courseSectionNumber != nil {
            let sectionNameLabel = cell.viewWithTag(102) as! UILabel
            sectionNameLabel.text = announcement.courseName + "-" + announcement.courseSectionNumber
        }
        
        let dateLabel = cell.viewWithTag(101) as! UILabel
        
        if announcement.date != nil {
            if let announcementDate = announcement.date {
                dateLabel.text = self.datetimeOutputFormatter()!.string(from: announcementDate)
            } else {
                dateLabel.text = ""
            }
        } else {
            dateLabel.text = ""
        }
    }

    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Daily Announcement Cell", for: indexPath) as UITableViewCell
        cell.accessibilityTraits = UIAccessibilityTraitButton
        configureCell(cell, atIndexPath:indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView,
        heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        let numberOfSections = announcementController!.sections?.count
        return numberOfSections!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let numberOfRowsInSection = announcementController!.sections?[section].numberOfObjects
        
        if numberOfRowsInSection == 0 {
            showNoDataView()
        } else {
            hideNoDataView()
        }
        
        return numberOfRowsInSection!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if let sections = announcementController!.sections {
            return sections[section].name
        } else {
            return nil
        }
    }
    
    func datetimeOutputFormatter() ->DateFormatter? {
        
        if (myDatetimeOutputFormatter == nil) {
            myDatetimeOutputFormatter = DateFormatter()
            myDatetimeOutputFormatter!.timeStyle = .short
            myDatetimeOutputFormatter!.dateStyle = .short
        }
        return myDatetimeOutputFormatter
    }
    
    
    func noDataView() ->UIView? {
        if myNoDataView == nil {
            myNoDataView = UIView(frame: CGRect(x:0,y:0,width:announcementTableWidthConstraint.constant, height:40.0))
            
            let constrainedView = UIView()
            constrainedView.translatesAutoresizingMaskIntoConstraints = false
            myNoDataView?.addSubview(constrainedView)
            
            myNoDataView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[constrainedView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["constrainedView":constrainedView]))
            myNoDataView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[constrainedView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["constrainedView":constrainedView]))
            
            
            let noMatchesLabel = UILabel(frame:CGRect(x:0,y:0,width:announcementTableWidthConstraint.constant, height:40.0))
            noMatchesLabel.font = UIFont.systemFont(ofSize: 14)
            noMatchesLabel.numberOfLines = 1;
            noMatchesLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
            noMatchesLabel.textAlignment = NSTextAlignment.left
            noMatchesLabel.text = NSLocalizedString("No announcements for today", comment:"no announcements for today message")
            
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
            
            announcementTableView.insertSubview(myNoDataView!, belowSubview:announcementTableView)
            announcementTableHeightConstraint.constant =  90.0
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
