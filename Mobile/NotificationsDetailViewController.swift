//
//  NotificationsDetailViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/13/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WebKit

class NotificationsDetailViewController : UIViewController, WKNavigationDelegate, UINavigationControllerDelegate {
    
    var notification : EllucianNotification?
    var module : Module?
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var webContainerView: UIView!
    
    @IBOutlet var actionButton: UIButton!
    
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var trashButton: UIBarButtonItem!
    @IBOutlet var trashFlexSpace: UIBarButtonItem!
    
    var webView: WKWebView?
    
    let dateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
        }()
    
    override func loadView() {
        super.loadView()
        self.webView = WKWebView()
        self.webView?.navigationDelegate = self
        self.webView?.translatesAutoresizingMaskIntoConstraints = false
        
        self.webContainerView.addSubview(self.webView!)
        
        let viewsDictionary = ["webView": webView!, "webViewContainer": webContainerView!]
        
        webContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[webView]-|",
            options: .alignAllLastBaseline,
            metrics: nil,
            views: viewsDictionary))
        
        // Create and add the horizontal constraints
        webContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[webView]-|",
            options: .alignAllLastBaseline,
            metrics: nil,
            views: viewsDictionary))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.topViewController!.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem
        self.navigationController!.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        
        if let label = notification!.linkLabel {
            self.actionButton.setTitle(label, for: UIControlState())
        } else {
            self.actionButton.removeFromSuperview()
        }

        if notification?.sticky != nil && notification?.sticky?.boolValue == true {
            let items = toolbar.items!.filter({ $0.tag == 0 })
            toolbar.setItems(items, animated: false)
        }
        
        titleLabel.text = notification!.title
        dateLabel.text = dateFormatter.string(from: notification!.noticeDate! as Date)

        loadWebView()
        DispatchQueue.global(qos: .utility).async {
            self.markNotificationRead()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sendView( "Notifications Detail", moduleName: module?.name)
    }
    
    func loadWebView() {
        var htmlStringWithFont : String

        if let description = notification?.notificationDescription {
            let text = description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            let pointSize = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body).pointSize
            

            htmlStringWithFont = "<meta name=\"viewport\" content=\"initial-scale=1.0\" /><div style=\"font-family: -apple-system; color:black; font-size: \(pointSize);\">\(text)</div>"

            // Replace '\n' characters with <br /> for content that isn't html based to begin with...
            // One issue is if html text also has \n characters in it. In that case we'll be changing the spacing of the content.
            htmlStringWithFont = htmlStringWithFont.replacingOccurrences(of: "\n", with: "<br/>")
            let _ = self.webView?.loadHTMLString(htmlStringWithFont, baseURL: nil)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping ((WKNavigationActionPolicy) -> Void)) {
        
        if navigationAction.navigationType == .linkActivated{
            UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        } else{
            decisionHandler(.allow)
        }
    }
    
    //MARK: segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Notification Link" {
            self.sendEventToTracker1(category: .ui_Action, action: .follow_web, label: "Open notification in web frame", moduleName: self.module?.name)
            
            let detailController = segue.destination as! WKWebViewController
            detailController.loadRequest = URLRequest(url: URL(string: self.notification!.hyperlink!)!)
            detailController.title = self.notification!.linkLabel
            detailController.analyticsLabel = self.module?.name
        }
    }
    
    //MARK: UINavigationControllerDelegate
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.viewWillAppear(animated)
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        viewController.viewDidAppear(animated)
    }
    
    //MARK: notifications API
    func markNotificationRead() {
        let urlBase = self.module!.property(forKey: "mobilenotifications")!
        let userid =  CurrentUser.sharedInstance.userid?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let urlString = "\(urlBase)/\(userid!)/\(notification!.notificationId!)"
        
        var urlRequest = URLRequest(url: URL(string: urlString)!)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if (LoginExecutor.isUsingBasicAuthentication()) {
            urlRequest.addAuthenticationHeader()
        }
        
        urlRequest.httpMethod = "POST"
        
        let postDictionary : [String : Any] = ["uuid": self.notification!.notificationId!, "statuses" : ["READ"]]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: postDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            urlRequest.httpBody = jsonData

            let defaultSession = URLSession(configuration: .default)
            defaultSession.dataTask(with: urlRequest as URLRequest).resume()

            self.notification!.read = true
            try self.notification?.managedObjectContext?.save()
        } catch {
        }
        
    }
    
    //MARK: button actions
    

    @IBAction func deleteNotification(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment:"Cancel"), style: .cancel) { action -> Void in
        }
        alertController.addAction(cancelAction)
        //Create and add first option action
        let deleteAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Delete", comment:"Delete button"), style: .destructive) { action -> Void in
            NotificationsFetcher.deleteNotification(notification: self.notification!, module: self.module!)
            
            if self.splitViewController!.isCollapsed {
                self.performSegue(withIdentifier: "Show Empty", sender: nil)
                let _ = self.navigationController?.navigationController?.popToRootViewController(animated: true)
            } else {
                self.performSegue(withIdentifier: "Show Empty", sender: nil)
            }
        }
        alertController.addAction(deleteAction)
        alertController.popoverPresentationController?.barButtonItem = sender;
        
        //Present the AlertController
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        
        let text : String
        if let description = self.notification?.notificationDescription, let link = self.notification?.hyperlink, !description.isEmpty && !link.isEmpty {
            text = "\(description) \(link)"
        } else if let description = self.notification?.notificationDescription, !description.isEmpty  {
            text = description
        } else if let link = self.notification?.hyperlink, !link.isEmpty {
            text = link
        } else {
            text = notification?.title ?? ""
        }
        
        let itemProvider = NotificationUIActivityItemProvider(subject: notification?.title ?? "", text: text)
        let activityVC = UIActivityViewController(activityItems: [itemProvider], applicationActivities: nil)
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
}
