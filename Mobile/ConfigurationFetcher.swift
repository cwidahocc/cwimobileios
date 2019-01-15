//
//  ConfigurationFetcher.swift
//  Mobile
//
//  Created by Jason Hocker on 7/11/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class ConfigurationFetcher {
    
    static let ConfigurationFetcherErrorNotification = Notification.Name("ConfigurationFetcherErrorNotification")
    
    class func showErrorAlertView(controller: UIViewController) {

        let alertController: UIAlertController = UIAlertController(title: NSLocalizedString("Unable to launch configuration", comment: "unable to download configuration title"), message: NSLocalizedString("Unable to download the configuration from that link", comment: "unable to download configuration message"), preferredStyle: .alert)
        let okAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
        alertController.addAction(okAction)
        controller.present(alertController, animated: true, completion: nil)
    }
}
