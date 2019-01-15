//
//  FeedDetailViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 7/31/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WebKit

class FeedDetailViewController: UIViewController, UIWebViewDelegate {
    
    static let feedDetailNotification = Notification.Name("FeedDetail viewWillAppear")
    
    var feed : Feed?
    var module : Module?
    var htmlStringWithFont : String?
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    
 
    @IBOutlet var webView: UIWebView!
    
    let dateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.topViewController!.navigationItem.leftBarButtonItem = splitViewController!.displayModeButtonItem
        self.navigationController!.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        
        titleLabel.text = feed!.title
        dateLabel.text = dateFormatter.string(from: feed!.postDateTime)

        if let logo = feed!.logo , logo != "" {
//            imageView.convertToCircleImage()
            imageView.loadImagefromURL(logo)
        }

        webView.delegate = self;
        loadWebView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sendView("News Detail", moduleName: module?.name)
        
        // Send notification to ensure that FeedViewController searchController resets
        NotificationCenter.default.post(name: FeedDetailViewController.feedDetailNotification, object: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.webView?.loadHTMLString(htmlStringWithFont!, baseURL: nil)
    }
    
    func loadWebView() {
        let text : String
        let link = feed?.link?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if let content = feed?.content {
            if let link = link, !link.isEmpty {
                text = "\(content)<br><br>\(link)"
            } else {
                text = content
            }
        } else if let link = link, !link.isEmpty {
            text = link
        } else {
            text = ""
        }
        
        let pointSize = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body).pointSize
        
        
        htmlStringWithFont = "<meta name=\"viewport\" content=\"initial-scale=1.0\" /><div style=\"font-family: -apple-system; color:black; font-size: \(pointSize);\">\(text)</div>"

        // Replace '\n' characters with <br /> for content that isn't html based to begin with...
        // One issue is if html text also has \n characters in it. In that case we'll be changing the spacing of the content.
        htmlStringWithFont = htmlStringWithFont!.replacingOccurrences(of: "\n", with: "<br/>")
        self.webView?.loadHTMLString(htmlStringWithFont!, baseURL: nil)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            UIApplication.shared.open(request.url!, options: [:], completionHandler: nil)
            return false;
        }
        return true;
    }
    
    @IBAction func share(_ sender: UIBarButtonItem) {
    
        var itemsToShare : [Any]
        var activities : [UIActivity]?
        
        activities = nil
        
        var shareString = ""
        if let feed = self.feed {
            if let title = feed.title {
                shareString += title
            }
            if let date = dateLabel.text {
                if !shareString.isEmpty {
                    shareString += "\n\n"
                }
                shareString += "Date: "
                shareString += date
            }
            if let content = feed.content {
                if !shareString.isEmpty {
                    shareString += "\n\n"
                }
                shareString += content.convertingHTMLToPlainText()
                shareString += "\n\n"
            }
            
        }
        itemsToShare = [shareString]
        
        if let link = self.feed?.link, let url = URL(string: link), link != "" {
            itemsToShare.append(url)
            activities = [SafariActivity()]
        }
        
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
}
