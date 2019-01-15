//
//  AboutViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 7/21/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class AboutViewController : UIViewController {
    
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var schoolLogo: UIImageView!
    
    @IBOutlet var serverVersion: UILabel!
    @IBOutlet var clientVersion: UILabel!
    @IBOutlet var clientVersionLabel: UILabel!
    @IBOutlet var serverVersionLabel: UILabel!
    
    @IBOutlet var contactTextView: UITextView!
    
    @IBOutlet var poweredByButton: UIButton!
    @IBOutlet var ellPrivacyButton: UIButton!
    
    @IBOutlet var phoneLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var websiteLabel: UILabel!
    @IBOutlet var privacyPolicyLabel: UILabel!
    @IBOutlet var separatorAfterPhoneView: UIView!
    @IBOutlet var separatorAfterEmailView: UIView!
    @IBOutlet var separatorAfterWebsiteView: UIView!
    
    @IBOutlet var phoneView: PseudoButtonView!
    @IBOutlet var emailView: PseudoButtonView!
    @IBOutlet var websiteView: PseudoButtonView!
    @IBOutlet var privacyPolicyView: PseudoButtonView!
    
    @IBOutlet var separatorAfterPhoneHeightConstraint: NSLayoutConstraint!
    @IBOutlet var separatorAfterEmailHeightConstraint: NSLayoutConstraint!
    @IBOutlet var separatorAfterWebsiteHeightConstraint: NSLayoutConstraint!
    @IBOutlet var phoneLabelLabel: UILabel!
    @IBOutlet var emailLabelLabel: UILabel!
    @IBOutlet var privacyPolicyLabelLabel: UILabel!
    
    @IBOutlet var websiteLabelLabel: UILabel!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var contactTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneLabel.accessibilityTraits = UIAccessibilityTraitButton
        emailLabel.accessibilityTraits = UIAccessibilityTraitButton
        websiteLabel.accessibilityTraits = UIAccessibilityTraitButton
        privacyPolicyLabel.accessibilityTraits = UIAccessibilityTraitButton
        
        self.serverVersion.textColor = UIColor.subheaderText
        self.serverVersionLabel.textColor = UIColor.subheaderText
        self.clientVersion.textColor = UIColor.subheaderText
        self.clientVersionLabel.textColor = UIColor.subheaderText
        let defaults = AppGroupUtilities.userDefaults()
        self.backgroundView.backgroundColor = UIColor.accent
        self.separatorAfterPhoneView.backgroundColor = UIColor.accent
        self.separatorAfterEmailView.backgroundColor = UIColor.accent
        self.separatorAfterWebsiteView.backgroundColor = UIColor.accent
        let contactInfo = defaults?.string(forKey: "about-contact")
        self.contactTextView.text = contactInfo
        var lastSeparator: NSLayoutConstraint? = nil
        let phoneNumber = defaults?.string(forKey: "about-phone-number")
        if let phoneNumber = phoneNumber, !phoneNumber.isEmpty {
            self.phoneLabel.text = phoneNumber
            self.phoneView.setAction(#selector(self.tapPhone), withTarget: self)
            lastSeparator = self.separatorAfterPhoneHeightConstraint
        }
        else {
            self.removeFromSuperviews(views: self.phoneView.subviews)
            self.separatorAfterPhoneHeightConstraint.constant = 0
            self.phoneView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(0)]", options: [], metrics: nil, views: ["view": self.phoneView]))
        }
        let email = defaults?.string(forKey: "about-email-address")
        if let email = email, !email.isEmpty {
            self.emailLabel.text = email
            self.emailView.setAction(#selector(self.tapEmail), withTarget: self)
            lastSeparator = self.separatorAfterEmailHeightConstraint
        }
        else {
            self.removeFromSuperviews(views: self.emailView.subviews)
            self.separatorAfterEmailHeightConstraint.constant = 0
            self.emailView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(0)]", options: [], metrics: nil, views: ["view": self.emailView]))
        }
        let website = defaults?.string(forKey: "about-website-url")
        if let website = website, !website.isEmpty {
            self.websiteLabel.text = website
            self.websiteView.setAction(#selector(self.tapWebsite), withTarget: self)
            lastSeparator = self.separatorAfterWebsiteHeightConstraint
        }
        else {
            self.removeFromSuperviews(views: self.websiteView.subviews)
            self.separatorAfterWebsiteHeightConstraint.constant = 0
            self.websiteView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(0)]", options: [], metrics: nil, views: ["view": self.websiteView]))
        }
        let privacy = defaults?.string(forKey: "about-privacy-url")
        let privacyDisplayString = defaults?.string(forKey: "about-privacy-display")
        if let privacy = privacy, !privacy.isEmpty {
            self.privacyPolicyLabel.text = privacyDisplayString
            self.privacyPolicyView.setAction(#selector(self.tapPrivacyPolicy), withTarget: self)
        }
        else {
            self.removeFromSuperviews(views: self.privacyPolicyView.subviews)
            lastSeparator?.constant = 0
            self.privacyPolicyView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(0)]", options: [], metrics: nil, views: ["view": self.privacyPolicyView]))
        }
        self.clientVersion.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        self.retrieveVersion()
        self.loadImage()
        self.toolbar.barTintColor = UIColor.primary
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sendView("About Page")
        let sizeThatShouldFitTheContent = self.contactTextView.sizeThatFits(self.contactTextView.frame.size)
        self.contactTextViewHeightConstraint.constant = sizeThatShouldFitTheContent.height
    }
    
    func loadImage() {
        let defaults = AppGroupUtilities.userDefaults()
        if let aboutLogoUrl = defaults?.string(forKey: "about-logoUrlPhone") {
            
            DispatchQueue.global().async {
                if let url = URL(string: aboutLogoUrl) {
                    if let imageData = try? Data(contentsOf: url) {
                        var myimage = UIImage(data: imageData)!
                        //assume it's a retina image and scale accordingly
                        myimage = UIImage(cgImage: myimage.cgImage!, scale: 2.0, orientation: .up)
                        DispatchQueue.main.async {
                            self.schoolLogo.image = myimage
                        }
                    }
                }
            }
        }
    }
    
    func retrieveVersion() {
        //retrieve server version in the background
        let defaults = AppGroupUtilities.userDefaults()
        if let versionURL = defaults?.string(forKey: "about-version-url") {
            
            DispatchQueue.global().async {
                let serverVersion : String
                if let versionResponseData = try? Data(contentsOf: URL(string: versionURL)!) {
                    let versionJson = JSON(data: versionResponseData)
                    serverVersion = versionJson["application"]["version"].stringValue
                    
                    defaults?.set(serverVersion, forKey: "application")
                    
                    
                } else {
                    print("Unable to download data from \(versionURL)")
                    serverVersion = ""
                }
                DispatchQueue.main.async {
                    self.serverVersion.text = serverVersion
                }
            }
        }
    }
    
    // MARK: - Table view data source
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let defaults = AppGroupUtilities.userDefaults()
        self.resetScrollViewContentOffset()
        if (segue.identifier == "webView") {
            self.sendEvent(category: .ui_Action, action: .follow_web, label: "About Web", moduleName: nil)
            let detailController: WKWebViewController = (segue.destination as! WKWebViewController)
            detailController.loadRequest = URLRequest(url: URL(string: (defaults?.string(forKey: "about-website-url"))!)!)
            detailController.title = defaults?.string(forKey: "about-website-display")
            detailController.analyticsLabel = NSLocalizedString("About", comment: "About menu item")
        }
        else if (segue.identifier == "policyView") {
            self.sendView("School Privacy", moduleName: nil)
            let detailController: WKWebViewController = (segue.destination as! WKWebViewController)
            detailController.loadRequest = URLRequest(url: URL(string: (defaults?.string(forKey: "about-privacy-url"))!)!)
            detailController.title = defaults?.string(forKey: "about-privacy-display")
            detailController.analyticsLabel = NSLocalizedString("About", comment: "About menu item")
        }
        else if (segue.identifier == "poweredBy") {
            self.sendEvent(category: .ui_Action, action: .invoke_Native, label: "About Text", moduleName: nil)
            let detailController: WKWebViewController = (segue.destination as! WKWebViewController)
            detailController.loadRequest = URLRequest(url: URL(string: "https://www.ellucian.com")!)
            detailController.title = NSLocalizedString("Ellucian", comment: "Ellucian")
            detailController.analyticsLabel = NSLocalizedString("About", comment: "About menu item")
        }
        else if (segue.identifier == "ellucianPrivacy") {
            self.sendView("Ellucian Privacy", moduleName: nil)
            let detailController: WKWebViewController = (segue.destination as! WKWebViewController)
            detailController.loadRequest = URLRequest(url: URL(string: "https://www.ellucian.com/privacy")!)
            detailController.title = NSLocalizedString("Ellucian Privacy", comment: "Ellucian privacy policy label")
            detailController.analyticsLabel = NSLocalizedString("About", comment:  "About menu item")
        }
        
    }
    
    @objc func tapPhone(sender: AnyObject) {
        self.sendEvent(category: .ui_Action, action: .invoke_Native, label: "About Phone", moduleName: nil)
        let phoneNumber = AppGroupUtilities.userDefaults()?.string(forKey: "about-phone-number")
        if let phone = phoneNumber?.components(separatedBy: CharacterSet(charactersIn: "() -")).joined(separator: "") {
            UIApplication.shared.open(URL(string: "tel://\(phone)")!, options: [:], completionHandler: nil)
        }
    }
    
    @objc func tapEmail(sender: AnyObject) {
        self.sendEvent(category: .ui_Action, action: .invoke_Native, label: "About Email", moduleName: nil)
        if let email = AppGroupUtilities.userDefaults()?.string(forKey: "about-email-address") {
            UIApplication.shared.open(URL(string: "mailto://\(email)")!, options: [:], completionHandler: nil)
        }
    }
    
    @objc func tapWebsite(sender: AnyObject) {
        self.performSegue(withIdentifier: "webView", sender: nil)
    }
    
    @objc func tapPrivacyPolicy(sender: AnyObject) {
        self.performSegue(withIdentifier: "policyView", sender: nil)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        let sizeThatShouldFitTheContent = self.contactTextView.sizeThatFits(self.contactTextView.frame.size)
        self.contactTextViewHeightConstraint.constant = sizeThatShouldFitTheContent.height
        self.resetScrollViewContentOffset()
    }
    
    func resetScrollViewContentOffset() {
        self.contactTextView.setContentOffset(CGPoint.zero, animated: true)
        self.scrollView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    private func removeFromSuperviews(views: [UIView]) {
        for view in views {
            view.removeFromSuperview()
        }
    }
}
