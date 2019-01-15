//
//  WatchConnectivity-Session.swift
//  Mobile
//
//  Created by Bret Hansen on 9/14/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WatchConnectivity

@available(iOS 9.0, *)
extension WatchConnectivityManager:WCSessionDelegate {
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activation did complete with status")
    }
    
    @available(iOS 9.3, *)
    func  sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    @available(iOS 9.3, *)
    func  sessionDidDeactivate(_ session: WCSession) {
        print("WCSession did deactivate")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("WCSession reachability did change: \(session.isReachable)")
        if refreshUserAfterReachable && session.isReachable {
            refreshUserAfterReachable = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.refreshUser()
            }
        }
        
    }
    
    // requests from watch to phone
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        var response = [String: Any]()
        
        var processClosure = {
            let action = message["action"] as! String
            print("WatchConnectivityManager didReceiveMessage action: \(action)")
            switch (action) {
            case "ping":
                print("WatchConnectivityManager received action=ping message")
                break
            case "fetch user":
                print("WatchConnectivityManager received action=fetch user message")
                #if os(iOS)
                    response["user"] = CurrentUser.sharedInstance.userAsPropertyListDictionary()
                #endif
                break
            case "fetch configuration":
                print("WatchConnectivityManager received action=fetch configuration message")
                #if os(iOS)
                    if let configurationData = ConfigurationManager.shared.mostRecentConfigurationData() {
                        response["configurationData"] = configurationData
                    } else {
                        print("WatchConnectivityManager didReceiveMessage configuration data wasn't cached - refresh it now and send to watch")
                        
                        // just send the configuration url, let the watch fetch configuration
                        if let configurationUrl = ConfigurationManager.shared.getConfigurationUrl() {
                            response["configurationUrl"] = configurationUrl
                        }
                    }
                #endif
                break
            case "fetch maps":
                print("WatchConnectivityManager received action=fetch maps message")
                #if os(iOS)
                    let internalKey = message["internalKey"] as! String
                    let url = message["url"] as! String
                    
                    let operation = MapsFetchOperation(internalKey: internalKey, url: url)
                    OperationQueue.main.addOperation(operation)
                    
                    operation.waitUntilFinished()
                    
                    response["campuses"] = operation.campuses
                #endif
                break;
            case "fetch assignments":
                print("WatchConnectivityManager received action=fetch assignments message")
                #if os(iOS)
                    let internalKey = message["internalKey"] as! String
                    let url = message["url"] as! String
                    
                    let operation = ILPAssignmentsFetchOperation(internalKey: internalKey, url: url)
                    OperationQueue.main.addOperation(operation)
                    
                    operation.waitUntilFinished()
                    
                    response["assignments"] = operation.assignments
                #endif
                break;
            default:
                // use NotificationCenter to notify for other actions
                NotificationCenter.default.post(name: WatchConnectivityManager.receivedMessage, object: message)
                break
            }
            
            // send reply with any associated data
            replyHandler(response)
        }
        
        #if os(iOS)
            // allow these to run as a background task
            let taskIdentifier = UIApplication.shared.beginBackgroundTask(){ () -> Void in }
            
            DispatchQueue.global(qos: .userInteractive).async {
                print("Running Process in background")
                processClosure()
                UIApplication.shared.endBackgroundTask(taskIdentifier)
            }
            
        #else
            processClosure()
        #endif
    }
}
