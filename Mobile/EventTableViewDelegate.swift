//
//  EventTableViewDelegate.swift
//  Mobile
//
//  Created by Alan McEwan on 1/20/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation


class EventTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate
{
    var eventTableView: UITableView
    var eventController: NSFetchedResultsController<CourseEvent>?
    var eventTableHeightConstraint: NSLayoutConstraint
    var eventTableWidthConstraint: NSLayoutConstraint
    var myDatetimeOutputFormatter: DateFormatter?
    var module:Module!
    var myNoDataView:UIView?
    
    init(tableView: UITableView, controller: NSFetchedResultsController<CourseEvent>, heightConstraint: NSLayoutConstraint, widthConstraint: NSLayoutConstraint, parentModule:Module) {
        
        eventTableView = tableView
        eventController = controller
        eventTableHeightConstraint = heightConstraint
        eventTableWidthConstraint = widthConstraint
        module = parentModule
        
        super.init()
        
        eventTableView.delegate = self
        eventTableView.dataSource = self
        
        eventController!.delegate = self
    }
    
    /* called first
    begins update to `UITableView`
    ensures all updates are animated simultaneously */
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        eventTableView.beginUpdates()
    }
    
    /* called:
    - when a new model is created
    - when an existing model is updated
    - when an existing model is deleted */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange object: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?) {
            switch type {
            case .insert:
                eventTableView.insertRows(at: [newIndexPath as IndexPath!], with: .fade)
            case .update:
                let cell = self.eventTableView.cellForRow(at: indexPath as IndexPath!)
                configureCell(cell!, atIndexPath: indexPath as IndexPath!)
                eventTableView.reloadRows(at: [indexPath as IndexPath!], with: .fade)
            case .move:
                eventTableView.deleteRows(at: [indexPath as IndexPath!], with: .fade)
                eventTableView.insertRows(at: [newIndexPath as IndexPath!], with: .fade)
            case .delete:
                eventTableView.deleteRows(at: [indexPath as IndexPath!], with: .fade)
            }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType)
    {
        switch(type) {
            
        case .insert:
            eventTableView.insertSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
            
        case .delete:
            eventTableView.deleteSections(IndexSet(integer: sectionIndex),
                with: UITableViewRowAnimation.fade)
            
        default:
            break
        }
    }

    /* called last
    tells `UITableView` updates are complete */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        eventTableView.endUpdates()
        eventTableHeightConstraint.constant = (CGFloat(eventController!.fetchedObjects!.count) * 50.0)  + 50.0
    }
    
    /* helper method to configure a `UITableViewCell`
    ask `NSFetchedResultsController` for the model */
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let event = eventController!.object(at: indexPath)
        
        if event.title != nil {
            let nameLabel = cell.viewWithTag(100) as! UILabel
            nameLabel.text = event.title
        }
        
        if event.courseName != nil && event.courseSectionNumber != nil {
            let courseSectionLabel = cell.viewWithTag(102) as! UILabel
            courseSectionLabel.text = event.courseName + "-" + event.courseSectionNumber
        }
        
        let startDateLabel = cell.viewWithTag(101) as! UILabel
        
        if event.startDate != nil {
            if let eventStartDate = event.startDate {
                startDateLabel.text = self.datetimeOutputFormatter()!.string(from: eventStartDate)
            } else {
                startDateLabel.text = ""
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Daily Event Cell", for: indexPath) as UITableViewCell
        cell.accessibilityTraits = UIAccessibilityTraitButton
        configureCell(cell, atIndexPath:indexPath)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        let numberOfSections = eventController!.sections?.count
        return numberOfSections!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let numberOfRowsInSection = eventController!.sections?[section].numberOfObjects
        
        if numberOfRowsInSection == 0 {
            showNoDataView()
        } else {
            hideNoDataView()
        }

        return numberOfRowsInSection!
    }
        
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if let sections = eventController!.sections {
            return sections[section].name
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView,
        heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func noDataView() ->UIView? {
        if myNoDataView == nil {
            myNoDataView = UIView(frame: CGRect(x:0,y:0,width:eventTableWidthConstraint.constant, height:40.0))
            
            let constrainedView = UIView()
            constrainedView.translatesAutoresizingMaskIntoConstraints = false
            myNoDataView?.addSubview(constrainedView)
            
            myNoDataView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[constrainedView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["constrainedView":constrainedView]))
            myNoDataView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[constrainedView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["constrainedView":constrainedView]))
            
            let noMatchesLabel = UILabel(frame:CGRect(x:0,y:0,width:eventTableWidthConstraint.constant, height:40.0))
            noMatchesLabel.font = UIFont.systemFont(ofSize: 14)
            noMatchesLabel.numberOfLines = 1;
            noMatchesLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
            noMatchesLabel.textAlignment = NSTextAlignment.left
            noMatchesLabel.text = NSLocalizedString("No events scheduled for today", comment:"no events scheduled for today message")
            
            
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
            
            eventTableView.insertSubview(myNoDataView!, belowSubview:eventTableView)
            eventTableHeightConstraint.constant =  90.0
        }
        return myNoDataView
    }
    
    func showNoDataView() {
        if ( myNoDataView == nil ) {
            myNoDataView = noDataView()
        }
        myNoDataView?.isHidden = false
    }
    
    func hideNoDataView() {
        self.myNoDataView?.isHidden = true
    }
    
    func datetimeOutputFormatter() ->DateFormatter? {
        
        if (myDatetimeOutputFormatter == nil) {
            myDatetimeOutputFormatter = DateFormatter()
            myDatetimeOutputFormatter!.timeStyle = .short
            myDatetimeOutputFormatter!.dateStyle = .short
        }
        return myDatetimeOutputFormatter
    }

}
