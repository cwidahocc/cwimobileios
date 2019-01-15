//
//  CopyLabel.swift
//  Mobile
//
//  Created by Jason Hocker on 7/15/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation


class CopyLabel : UILabel {
    // MARK: Initialization
    
    func attachTapHandler() {
        self.isUserInteractionEnabled = true
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleTap))
        self.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.attachTapHandler()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.attachTapHandler()
    }
    // MARK: Clipboard
    
    func copy(sender: AnyObject) {
        UIPasteboard.general.string = self.text!
    }
    
    @objc func unhighlight() {
        self.isHighlighted = false
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIMenuControllerWillHideMenu, object: nil)
    }

    @objc func handleTap(recognizer: UIGestureRecognizer) {
        self.becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            NotificationCenter.default.addObserver(self, selector: #selector(self.unhighlight), name: NSNotification.Name.UIMenuControllerWillHideMenu, object: nil)
            menu.setTargetRect(self.frame, in: self.superview!)
            menu.setMenuVisible(true, animated: true)
            self.isHighlighted = true
        }
    }
    
    override public var canBecomeFirstResponder: Bool { return true }
}
