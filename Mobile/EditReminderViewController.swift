//
//  EditReminderViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 4/6/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

public class EditReminderViewController: UITableViewController {
    
    @objc var reminderTitle : String?
    @objc var reminderDate : Date?
    @objc var reminderNotes : String?
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var reminderSwitch: UISwitch!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var notesTextView: UITextView!
    @IBOutlet var reminderListLabel: UILabel!
    
    private var datePickerHidden = false
    let eventStore : EKEventStore = {
        return EKEventStore()
    }()
    var selectedCalendar : EKCalendar?
    
    
    public override func viewDidLoad() {
        titleLabel.text = reminderTitle
        notesTextView.text = reminderNotes
        if let date = reminderDate {
            datePicker.date = date
        }
        eventStore.requestAccess(to: .reminder) {
            granted, error in
            if (granted) && (error == nil) {
                self.selectedCalendar = self.eventStore.defaultCalendarForNewReminders()
                self.didChangeCalendar()
            } else {
                self.showPermissionNotGrantedAlert()
                self.dismiss(animated: true, completion: {});
            }
        };
        didChangeDate()
        toggleDatePicker()
    }
    
    @IBAction func didChangeDate() {
        dateLabel.text = DateFormatter.localizedString(from: datePicker.date, dateStyle: .short, timeStyle: .short)
    }
    
    func didChangeCalendar() {
        if let selectedCalendar = selectedCalendar {
            DispatchQueue.main.async(execute: {
                self.reminderListLabel.text = selectedCalendar.title
            })
        }
    }
    
    @IBAction func add(_ sender: AnyObject) {
        eventStore.requestAccess(to: .reminder) {
            granted, error in
            if granted {
                let reminder:EKReminder = EKReminder(eventStore: self.eventStore)
                reminder.title = self.titleLabel.text!
                reminder.calendar = self.selectedCalendar!
                
                if self.reminderSwitch.isOn {
                    
                    let calendar = Calendar.current
                    let dueDateComponents = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .second] , from: self.datePicker.date)
                    reminder.dueDateComponents = dueDateComponents
                    let alarm:EKAlarm = EKAlarm(absoluteDate: self.datePicker.date)
                    reminder.alarms = [alarm]
                }
                reminder.notes = self.notesTextView.text
                
                do {
                    try self.eventStore.save(reminder, commit: true)
                } catch  {
                }
                self.dismiss(animated: true, completion: {});
            } else {
                self.showPermissionNotGrantedAlert()
            }
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: {});
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch ((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (1, 1):
            tableView.deselectRow(at: indexPath, animated: false)
            toggleDatePicker()
        case (2, 0):
            tableView.deselectRow(at: indexPath, animated: false)
            showCalendarList()
        default:
            ()
        }
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if datePickerHidden && (indexPath as NSIndexPath).section == 1 && (indexPath as NSIndexPath).row == 2 {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    private func toggleDatePicker() {
        datePickerHidden = !datePickerHidden
        
        // Force table to update its contents
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    public override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch ((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (1, 1), (2, 0):
            return true
        default:
            return false
        }
        
    }
    
    private func showCalendarList() {
        
        
        let alertController = UIAlertController(title: NSLocalizedString("Reminder List", comment: "title of reminder list alert picker"), message: NSLocalizedString("Select the name of the reminder list to use.", comment: "Title of the action sheet to select a reminder list to save the reminder"), preferredStyle: .actionSheet)
        
        let calendars = eventStore.calendars(for: .reminder)
        for calendar in calendars {
            let action = UIAlertAction(title: calendar.title, style: .default) { value in
                self.setCalendarWithName(value.title!)
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        
        
    }
    
    private func setCalendarWithName(_ calendarName: String) {
        let calendars = eventStore.calendars(for: .reminder)
        let filteredCalendars = calendars.filter({ (calendar: AnyObject) -> Bool in
            return calendar.title == calendarName
        })
        if(filteredCalendars.count > 0) {
            selectedCalendar = filteredCalendars[0]
            didChangeCalendar()
        }
    }
    
    private func showPermissionNotGrantedAlert() {
        
        
        let alertController = UIAlertController(title: NSLocalizedString("Permission not granted", comment: "Permission not granted title"), message: NSLocalizedString("You must give permission in Settings to allow access", comment: "Permission not granted message. Settings application is part of iOS.  Apple translates this to be Arabic = الإعدادات Spanish/Portuguese=Ajustes French=Réglages"), preferredStyle: .alert)
        
        
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings application name. This is part of iOS.  Apple translates this to be Arabic = الإعدادات Spanish/Portuguese=Ajustes French=Réglages"), style: .default) { value in
            let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .default, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            () -> Void in
            self.present(alertController, animated: true, completion: nil)
            
        }
        
    }
}
