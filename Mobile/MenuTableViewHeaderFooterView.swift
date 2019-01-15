//
//  MenuTableViewHeaderFooterView.swift
//  Mobile
//
//  Created by Jason Hocker on 7/13/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class MenuTableViewHeaderFooterView : UITableViewHeaderFooterView {
    
    var headerLabel : UILabel?
    var collapsibleButton : UIButton?
    var delegate : SectionHeaderViewDelegate?
    var section : Int?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        let collapsible = reuseIdentifier == "CollapseableHeader"
        let backgroundColor = UIColor.black
        if self.backgroundColor != backgroundColor {
            self.contentView.backgroundColor = backgroundColor
            self.contentView.isOpaque = true
            
            headerLabel = UILabel()
            headerLabel!.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
            headerLabel!.textColor = UIColor(red: 179/255, green: 179/255, blue: 179/255, alpha: 1)
            headerLabel!.isOpaque = false
            self.contentView.addSubview(headerLabel!)
            headerLabel!.translatesAutoresizingMaskIntoConstraints = false
            headerLabel?.accessibilityTraits |= UIAccessibilityTraitHeader

    
            if(collapsible) {
                collapsibleButton = UIButton()
                collapsibleButton!.setImage(UIImage(named:"menu header expanded"), for: UIControlState())
                collapsibleButton!.setImage(UIImage(named:"menu header collapsed"), for: .selected)
                collapsibleButton!.addTarget(self, action: #selector(MenuTableViewHeaderFooterView.toggleHeader), for: .touchUpInside)
                self.contentView.addSubview(collapsibleButton!)
                collapsibleButton!.translatesAutoresizingMaskIntoConstraints = false
                collapsibleButton!.accessibilityLabel = NSLocalizedString("Toggle menu section", comment:"Accessibility label for toggle menu section button")
            }


            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-13-[headerLabel]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["headerLabel" : headerLabel!]))
                
            if(collapsible) {
                self.contentView.addConstraint(NSLayoutConstraint(item: collapsibleButton!, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1.0, constant: 267.0))
            }
            
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[headerLabel]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["headerLabel": headerLabel!]))
            
            if(collapsible) {
                self.contentView.addConstraint(NSLayoutConstraint(item: collapsibleButton!, attribute: .centerY, relatedBy: .equal, toItem: headerLabel!, attribute: .centerY, multiplier: 1.0, constant: 0))
            }
        }
        
        if(collapsible) {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MenuTableViewHeaderFooterView.toggleHeader))
            self.addGestureRecognizer(tapGestureRecognizer)
        }

    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func toggleHeader() {
        self.collapsibleButton!.isSelected = !self.collapsibleButton!.isSelected
        
        if self.collapsibleButton!.isSelected {
            self.delegate?.sectionHeaderView!(self, sectionClosed: self.section!)
        } else {
            self.delegate?.sectionHeaderView!(self, sectionOpened: self.section!)
        }
    }
}

