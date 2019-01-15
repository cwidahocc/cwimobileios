//
//  CoursesCalendarDatePickerController.swift
//  Mobile
//
//  Created by Jason Hocker on 7/19/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class CoursesCalendarDatePickerController : UIViewController {
    
    var delegate : CoursesCalendarViewController?
    var date : Date?
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        if let date = self.date {
            datePicker.date = date
        }
    }

    @IBAction func done(_ sender: AnyObject) {
        if let delegate = delegate {
            let dayView = delegate.view as? CalendarViewDayView
            dayView?.day = datePicker.date
        }
        self.dismiss(animated: true, completion: nil)
    }

}
