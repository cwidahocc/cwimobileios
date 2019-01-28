//
//  TodayViewController.swift
//  AssignmentsToday
//
//  Created by Jason Hocker on 1/21/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UITableViewController, NCWidgetProviding {
    
    var items : [NSDictionary]?
    var noILP : Bool = false
    var disconnected : Bool = false
    
    @IBOutlet var disconnectedFooter: UIView!
    @IBOutlet var noILPFooter: UIView!
    @IBOutlet var noItemsFooter: UIView!
    @IBOutlet var disconnectedFooterIOS9: UIView!
    @IBOutlet var noILPFooterIOS9: UIView!
    
    @IBOutlet var noItemsFooterIOS9: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = AppGroupUtilities.userDefaults()
        items = defaults?.object(forKey: "today-widget-assignments") as! [NSDictionary]?
        self.reloadTable()

        self.disconnected = UserInfo.userauth() == nil
    }
    
    func widgetPerformUpdate(completionHandler: @escaping ((NCUpdateResult) -> Void)) {
        fetch()
        
        completionHandler(NCUpdateResult.newData)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let items = self.items {
            if #available(iOSApplicationExtension 10.0, *) {
                if self.extensionContext?.widgetActiveDisplayMode == .compact {
                    return min(2, items.count)
                }
            }
            return items.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let itemNumber = (indexPath as NSIndexPath).row
        let cell : UITableViewCell
        
        if #available(iOSApplicationExtension 10.0, *) {
            cell = tableView.dequeueReusableCell(withIdentifier: "Assignment Today Cell", for: indexPath) as UITableViewCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "Assignment Today Cell iOS 9", for: indexPath) as UITableViewCell
        }
        cell.accessibilityTraits = UIAccessibilityTraitButton
        
        if let items = self.items {
            let item = items[itemNumber]
            (cell.contentView.viewWithTag(1) as! UILabel).text = item["name"] as! String?
            let courseName = item["courseName"]
            let courseSectionNumber = item["courseSectionNumber"]
            (cell.contentView.viewWithTag(2) as! UILabel).text = "\(courseName!)-\(courseSectionNumber!)"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemNumber = (indexPath as NSIndexPath).row
        if let items = self.items {
            let item = items[itemNumber]
            let itemUrl = item["url"] as! String
            let scheme = getScheme()
            var allowedCharacters = CharacterSet.urlQueryAllowed
            allowedCharacters.remove(charactersIn: "&")
            let escapedString = itemUrl.addingPercentEncoding(withAllowedCharacters: allowedCharacters)!
            let urlString = "\(scheme)://module-type/ilp?url=\(escapedString)"
            let url = URL(string: urlString)
            self.extensionContext!.open(url!, completionHandler: nil)
        }
    }

    func reload() {
        self.tableView.reloadData()
        self.preferredContentSize = self.tableView.contentSize

    }
    
    func filterItems(_ items: [NSDictionary]) -> [NSDictionary]? {

        print("Start filtering")
        let sourceToDateFormatter = DateFormatter()
        sourceToDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        sourceToDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let comparisonFormatter = DateFormatter()
        comparisonFormatter.dateFormat = "yyyy-MM-dd"
        comparisonFormatter.timeZone = TimeZone.current
        let dateNow = Date()
        
        let dateNowString = comparisonFormatter.string(from: dateNow)
        
        let filteredArray = items.filter() { (item : NSDictionary) -> Bool in
            
            if let date = sourceToDateFormatter.date(from: item["dueDate"] as! String) {
                let dateString = comparisonFormatter.string(from: date)
                return dateNowString == dateString
            } else {
                return false
            }
        }
        print("End filtering")
        return filteredArray
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if #available(iOSApplicationExtension 10.0, *) {
            if(self.noILP) {
                return self.noILPFooter
            }
            else if(self.disconnected) {
                return self.disconnectedFooter
            }
            else if let items = self.items {
                if(items.count == 0) {
                    return self.noItemsFooter
                }
            }
        } else { //iOS 9
            if(self.noILP) {
                return self.noILPFooterIOS9
            }
            else if(self.disconnected) {
                return self.disconnectedFooterIOS9
            }
            else if let items = self.items {
                if(items.count == 0) {
                    return self.noItemsFooterIOS9
                }
            }

        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        var width = CGFloat(0)
        if(self.noILP) {
            width = self.noILPFooter.frame.height
        }
        else if(self.disconnected) {
            width = self.disconnectedFooter.frame.height
        }
        else if let items = self.items {
            if(items.count == 0) {
                width = self.noItemsFooter.frame.height
            }
        }
        return width
    }

    @IBAction func signIn(_ sender: AnyObject) {
        let scheme = getScheme()
        let url = URL(string: "\(scheme)://module-type/ilp")
        self.extensionContext!.open(url!, completionHandler: nil)
    }
    
    private func getScheme() -> String {
        var scheme = "ellucianmobile"
        if let path = Bundle.main.path(forResource: "Customizations", ofType: "plist") {
            let plistDictionary = NSDictionary(contentsOfFile: path)
            if let plistDictionary = plistDictionary {
                if let urlScheme = plistDictionary["URL Scheme"] as? String, !urlScheme.isEmpty {
                    scheme = urlScheme
                }
            }
        }
        return scheme
    }

    func fetch() {
        let defaults = AppGroupUtilities.userDefaults()
        let url = defaults?.object(forKey: "ilp-url") as! NSString?
        print("Assignments Today widgetPerformUpdateWithCompletionHandler")
        
        items = defaults?.object(forKey: "today-widget-assignments") as! [NSDictionary]?
        
        let storage = HTTPCookieStorage.shared
        if let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }

        let cookiesArray : NSArray? = defaults?.object(forKey: "cookieArray") as! NSArray?
        if let cookiesArray = cookiesArray {
            for cookieItem in cookiesArray  {
                let cookieDictionary = cookieItem
                let cookie = HTTPCookie(properties: cookieDictionary as! [HTTPCookiePropertyKey : AnyObject])
                HTTPCookieStorage.shared.setCookie(cookie!)
            }
        }

        if let ilpUrl = url {
            print("Assignments Today url: \(ilpUrl)")
            if let username = UserInfo.userauth() {
                print("Assignments Today has username")
                let config = URLSessionConfiguration.default
                let password = UserInfo.password()
                if let password = password {
                    let userPasswordString = "\(username):\(password)"
                    let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
                    let base64EncodedCredential = userPasswordData!.base64EncodedString()
                    let authString = "Basic \(base64EncodedCredential)"
                    config.httpAdditionalHeaders = ["Authorization" : authString]
                }
                let session = URLSession(configuration: config)
                
                if let studentId = UserInfo.userid() {
                    print("Assignments Today has studentId")
                    let fullUrl = URL(string: "\(ilpUrl)/\(studentId)/assignments")!
                    
                    
                    let task = session.dataTask(with: fullUrl) {
                        (data, response, error) in
                        
                        if let httpRes = response as? HTTPURLResponse {
                            print("Assignments Today response code: \(httpRes.statusCode)")
                            if httpRes.statusCode == 200 {
                                if(data == nil) {
                                    print("Assignments Today disconnected")
                                    self.disconnected = true
                                    self.reloadTable()
                                } else {
                                    let json = JSON(data: data!)
                                    var items = [NSDictionary]()
                                    let assignmentList: Array<JSON> = json["assignments"].arrayValue
                                    
                                    for assignmentJson in assignmentList {
                                        items.append(["sectionId" : assignmentJson["sectionId"].stringValue,
                                            "courseName": assignmentJson["courseName"].stringValue, "courseSectionNumber": assignmentJson["courseSectionNumber"].stringValue, "name": assignmentJson["name"].stringValue, "assignmentDescription": assignmentJson["description"].stringValue, "dueDate": assignmentJson["dueDate"].stringValue, "url": assignmentJson["url"].stringValue])
                                    }

                                    self.items = self.filterItems(items)
                                    
                                    self.reloadTable()
                                    defaults?.set(self.items, forKey: "today-widget-assignments")
                                    print("Assignments Today count: \(self.items!.count)")
                                }
                            } else {
                                self.disconnected = true
                                self.reloadTable()
                            }                            
                        }
                        if let error = error {
                            print("error \(error)")
                        }
                    }
                    task.resume()
                }
            } else {
                print("Assignments Today disconnected")
                self.disconnected = true
                reloadTable()
            }
        } else {
            print("Assignments Today no ILP")
            self.noILP = true
            reloadTable()
        }
    }
    
    func reloadTable() {
        print("Start reload")
        DispatchQueue.main.async {
            if #available(iOSApplicationExtension 10.0, *) {
                if let count = self.items?.count, count <= 2 {
                    self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
                } else {
                    self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
                }
            }
            self.reload()
            print("End reload")
        }
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
        self.preferredContentSize = (activeDisplayMode == .compact) ? maxSize : CGSize(width: maxSize.width, height: 200)
        self.reloadTable()
    }
}
