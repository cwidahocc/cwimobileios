//
//  StudentFinancialsViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 3/23/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class StudentFinancialsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, EllucianMobileLaunchableControllerProtocol {
    
    var module: Module!
    
    @IBOutlet var bottomViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var linkButton: UIButton!
    @IBOutlet var balanceLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    var transactions: [StudentFinancialsTransaction] = []
    
    let parsingDateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'";
        formatter.timeZone = TimeZone(abbreviation:"UTC")
        return formatter
        
        }()
    let displayDateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
        
        }()
    
    let currencyFormatter: NumberFormatter = {
        var formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
        }()
    
    override func viewDidLoad() {
        self.title = self.module?.name
        let linkLabel = self.module?.property(forKey: "externalLinkLabel")
        let linkUrl = self.module?.property(forKey: "externalLinkUrl")
        if linkLabel == nil || linkUrl == nil {
            linkButton.isHidden = true
            bottomViewHeightConstraint.constant = 0;
        } else {
            linkButton.setTitle(linkLabel, for: UIControlState())
            linkButton.setTitle(linkLabel, for: .selected)
            linkButton.addBorderAndColor()
        }
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        self.fetchData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sendView( "View Account Balance", moduleName:self.module?.name)
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count > 0 ? transactions.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if transactions.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Recent Payment Cell", for: indexPath) as UITableViewCell
            
            let transaction = transactions[(indexPath as NSIndexPath).row]
            let descriptionLabel = cell.viewWithTag(1) as! UILabel
            descriptionLabel.text = transaction.description
            let dateLabel = cell.viewWithTag(2) as! UILabel
            dateLabel.text = displayDateFormatter.string(from: transaction.entryDate as Date)
            let amountLabel = cell.viewWithTag(3) as! UILabel
            amountLabel.text = currencyFormatter.string(from: NSNumber(value: transaction.amount))
            
            
            return cell
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "No Transactions Cell", for: indexPath) as UITableViewCell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
        let label = UILabel(frame: CGRect(x: 8,y: 0,width: tableView.frame.width, height: 30))
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.text =  NSLocalizedString("RECENT PAYMENTS", comment: "Table section header RECENT PAYMENTS")
        
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        view.backgroundColor = UIColor(rgba: "#e6e6e6")
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        
        view.addSubview(label)
        
        let viewsDictionary = ["label": label, "view": view]
        
        // Create and add the vertical constraints
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-1-[label]-1-|",
            options: .alignAllLastBaseline,
            metrics: nil,
            views: viewsDictionary))
        
        // Create and add the horizontal constraints
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-20-[label]",
            options: .alignAllLastBaseline,
            metrics: nil,
            views: viewsDictionary))
        return view;
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func fetchData() {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        let loadingString = NSLocalizedString("Loading", comment: "loading message while fetching recent transactions")
        loadingNotification.label.text = loadingString
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.fetchTransactions()
            self.fetchBalance()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
    }
    
    func fetchTransactions() {
        
        let urlBase = self.module?.property(forKey: "financials")!
        let userid =  CurrentUser.sharedInstance.userid?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let urlString = "\(urlBase!)/\(userid!)/transactions"
        let url: URL? = URL(string: urlString as String)
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        let authenticatedRequest = AuthenticatedRequest()
        let responseData = authenticatedRequest.requestURL(url, fromView: self)
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        if let response = responseData {
            
            let json = JSON(data: response)
            let termsList: Array<JSON> = json["terms"].arrayValue
            currencyFormatter.currencyCode = json["currencyCode"].stringValue

            for termDictioanry in termsList {
                for transactionDictioanry in termDictioanry["transactions"].arrayValue {
                    let amount = transactionDictioanry["amount"].floatValue
                    let description = transactionDictioanry["description"].stringValue
                    let date = self.parsingDateFormatter.date(from: transactionDictioanry["entryDate"].stringValue)
                    let type = transactionDictioanry["type"].stringValue
                    let transaction = StudentFinancialsTransaction(amount: amount, description: description, entryDate: date!, type: type)
                    self.transactions.append(transaction)
                }
            }
            self.transactions.sort {
                item1, item2 in
                let date1 = item1.entryDate as Date
                let date2 = item2.entryDate as Date
                return date1.compare(date2) == ComparisonResult.orderedDescending
            }
        } else {
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment:"title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment:"message when data cannot load due to a poor netwrok connection"), preferredStyle: .alert)
                let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: UIAlertActionStyle.default)
                alertController.addAction(alertAction)
                self.present(alertController, animated: true)
            }
        }
    }
    
    func fetchBalance() {
        
        let urlString = NSString( format:"%@/%@/balances", self.module!.property(forKey: "financials")!, CurrentUser.sharedInstance.userid! )
        let url: URL? = URL(string: urlString as String)

        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    
        let authenticatedRequest = AuthenticatedRequest()
        let responseData = authenticatedRequest.requestURL(url, fromView: self)
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        if let response = responseData {
            
            let json = JSON(data: response)
            let termsList: Array<JSON> = json["terms"].arrayValue
            
            for termDictionary in termsList {
                let balance = termDictionary["balance"].floatValue
                DispatchQueue.main.async {
                    self.balanceLabel.text = self.currencyFormatter.string(from: NSNumber(value: balance));
                }
            }
        } else {
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: NSLocalizedString("Error", comment:""), message: NSLocalizedString("Data could not be reached", comment:""), preferredStyle: .alert)
                let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:""), style: UIAlertActionStyle.default)
                alertController.addAction(alertAction)
                self.present(alertController, animated: true)
            }
        }
    }
    @IBAction func gotoLink(_ sender: UIButton) {
        self.sendEvent(category: .ui_Action, action: .button_Press, label: "Open financial service", moduleName: self.module?.name)
        let external = self.module!.property(forKey: "external")
        if external != nil && external == "true" {
            let url = URL(string: self.module!.property(forKey: "externalLinkUrl")!)
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        } else {
            self.performSegue(withIdentifier: "Take action", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Take action"{
            let vc = segue.destination as! WKWebViewController
            vc.loadRequest = URLRequest(url: URL(string: self.module!.property(forKey: "externalLinkUrl")!)!)
            vc.title = self.module!.property(forKey: "externalLinkLabel")
            vc.analyticsLabel = self.module!.property(forKey: "externalLinkLabel")
        }
    }
}
