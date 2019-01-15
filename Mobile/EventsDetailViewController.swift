//
//  EventsDetailViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/10/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WebKit

class EventsDetailViewController: UIViewController, UIWebViewDelegate, EKEventEditViewDelegate {
    
    static let eventsDetailNotification = Notification.Name("EventsDetail viewWillAppear")
    
    let eventStore = EKEventStore()
    var event : Event?
    var module : Module?
    var htmlStringWithFont : String?
    
    @IBOutlet var webView: UIWebView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    
    let dateTimeFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
        }()
    let dateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
        }()
    let timeFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
        }()
    
    override func loadView() {
        super.loadView()

        self.webView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.topViewController!.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem
        self.navigationController!.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        
        if let event = event {
            titleLabel.text = event.summary
            locationLabel.text = event.location

            if event.allDay.boolValue == true {
                let dateString = dateFormatter.string(from: event.startDate!)
                let localizedAllDay = NSLocalizedString("All Day", comment: "label for all day event")
                dateLabel.text = "\(dateString) \(localizedAllDay)"
            } else {
                if let startDate = event.startDate, let endDate = event.endDate {
                    if isSameDate(event.startDate!, end: event.endDate) {
                        let formattedStart = self.dateTimeFormatter.string(from: startDate)
                        let formattedEnd = self.timeFormatter.string(from: endDate)
                        dateLabel.text = String(format: NSLocalizedString("%@ - %@", comment: "event start - end"), formattedStart, formattedEnd)

                    } else {
                        let formattedStart = self.dateTimeFormatter.string(from: startDate)
                        let formattedEnd = self.dateTimeFormatter.string(from: endDate)
                        dateLabel.text = String(format: NSLocalizedString("%@ - %@", comment: "event start - end"), formattedStart, formattedEnd)
                    }
                } else {
                    dateLabel.text = self.dateTimeFormatter.string(from: event.startDate)
                }
            }
        }
        
        loadWebView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sendView("News Detail", moduleName: module?.name)
        
        // Send notification to ensure that EventsViewController searchController resets
        NotificationCenter.default.post(name: EventsDetailViewController.eventsDetailNotification, object: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.webView?.loadHTMLString(htmlStringWithFont!, baseURL: nil)
    }
    
    func loadWebView() {
        let pointSize = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body).pointSize
        
        if let text = event?.description_ {
            htmlStringWithFont = "<meta name=\"viewport\" content=\"initial-scale=1.0\" /><div style=\"font-family: -apple-system; color:black; font-size: \(pointSize);\">\(text)</div>"
        } else {
            htmlStringWithFont = ""
        }
        // Replace '\n' characters with <br /> for content that isn't html based to begin with...
        // One issue is if html text also has \n characters in it. In that case we'll be changing the spacing of the content.
        htmlStringWithFont = htmlStringWithFont!.replacingOccurrences(of: "\n", with: "<br/>")
        self.webView?.loadHTMLString(htmlStringWithFont!, baseURL: nil)
    }
    
    func webView(_ webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        
        if navigationAction.navigationType == .linkActivated{
            UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        } else{
            decisionHandler(.allow)
        }
    }

    @IBAction func addToCalendar(_ sender: AnyObject) {
        let ekevent = EKEvent(eventStore: self.eventStore)
        ekevent.title = event!.summary
        ekevent.location = event!.location
        ekevent.startDate = event!.startDate
        ekevent.endDate = event!.endDate
        ekevent.notes = event!.description_
        ekevent.isAllDay = event!.allDay.boolValue
        
        let eventController = EKEventEditViewController()
        eventController.eventStore = self.eventStore
        eventController.event = ekevent
        eventController.editViewDelegate = self
        
        self.sendEvent(category: .ui_Action, action: .invoke_Native, label: "Add to Calendar", moduleName: self.module?.name)

        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            DispatchQueue.main.async(execute: { () -> Void in
                self.present(eventController, animated: true, completion: nil)
            })
            
        case .notDetermined:
            self.eventStore.requestAccess(to: EKEntityType.event, completion: { (granted, error) -> Void in
                if granted {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.present(eventController, animated: true, completion: nil)
                    })
                }
            })
        case .denied, .restricted:
            let alertController = UIAlertController(title: NSLocalizedString("Permission not granted", comment: "Permission not granted title"), message: NSLocalizedString("You must give permission in Settings to allow access", comment: "Permission not granted message"), preferredStyle: .alert)
            
            
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
    
    func eventEditViewController(_ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction) {
            self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        
        let itemsToShare : [Any]
        let activities : [UIActivity]?
        
        var shareString = ""
        if let event = self.event {
            if let summary = event.summary {
                shareString += summary
            }
            if let date = dateLabel.text {
                if !shareString.isEmpty {
                    shareString += "\n\n"
                }
                shareString += "Date: "
                shareString += date
            }
            if let location = event.location {
                if !shareString.isEmpty {
                    shareString += "\n\n"
                }
                shareString += "Location: "
                shareString += location
            }
            if let description = event.description_ {
                if !shareString.isEmpty {
                    shareString += "\n\n"
                }
                shareString += description
            }
        }
        itemsToShare = [shareString]
        activities = nil

        
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: activities)
        activityVC.popoverPresentationController?.barButtonItem = sender
        activityVC.completionWithItemsHandler = {
            (activityType, success, returnedItems, error) in
            if success {
                if let activityType = activityType {
                    let label = "Tap Share Icon - \(activityType.rawValue)"
                    self.sendEvent(category: .ui_Action, action: .invoke_Native, label: label, moduleName: self.module?.name)
                }
            }
        }
        
        self.present(activityVC, animated: true, completion: nil)
        
    }
    
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            UIApplication.shared.open(request.url!, options: [:], completionHandler: nil)
            return false;
        }
        return true;
    }
    
    func isSameDate(_ start: Date, end:Date) -> Bool {
        let calendar = Calendar.current
        let componentsForStartDate = calendar.dateComponents([.year, .month, .day], from: start)
        //end date is not inclusive so remove a second
        let includiveEnd = end.addingTimeInterval(-1);
        let componentsForEndDate = calendar.dateComponents([.year, .month, .day], from: includiveEnd)
        
       
        if componentsForStartDate.year == componentsForEndDate.year && componentsForStartDate.month == componentsForEndDate.month && componentsForStartDate.day == componentsForEndDate.day {
            return true
        } else {
            return false
        }
    }
}
