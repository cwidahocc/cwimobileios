//
//  DirectoryEntry.swift
//  Mobile
//
//  Created by Jason Hocker on 12/3/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class DirectoryEntry : NSObject {
    var personId : String?
    var username : String?
    var displayName : String?
    var firstName : String?
    var middleName : String?
    var lastName : String?
    var title : String?
    var office : String?
    var department : String?
    var phone : String?
    var mobile : String?
    var email : String?
    var street : String?
    var room : String?
    var postOfficeBox : String?
    var city : String?
    var state : String?
    var postalCode : String?
    var country : String?
    var prefix : String?
    var suffix : String?
    var imageUrl : String?
    var type : String?
    var nickName : String?
    
    
    @objc func nameToUseForDisplay() -> String {
        if let displayName = self.displayName {
            return displayName
        } else if let firstName = self.firstName, let lastName = self.lastName {
            var components = PersonNameComponents()
            components.givenName = firstName
            components.familyName = lastName
            return PersonNameComponentsFormatter.localizedString(from: components, style: .default)
        } else if let firstName = self.firstName {
            return firstName
        } else if let lastName = self.lastName {
            return lastName
        } else {
            return ""
        }
    }
    
    @objc func nameToUseForFirstNameSort() -> String {
        if let firstName = self.firstName {
            return firstName
        } else if let displayName = self.displayName {
            return displayName
        }
        else {
            return ""
        }
    }
    
    @objc func nameToUseForLastNameSort() -> String {
        if let lastName = self.lastName {
            return lastName
        } else if let displayName = self.displayName {
            return displayName
        }
        else {
            return ""
        }
    }
    
    class func parseResponse(_ responseData : Data) -> [DirectoryEntry] {
        var entries =  [DirectoryEntry]()
        
        let json = JSON(data: responseData)
        //create/update objects
        if json["entries"] != JSON.null {
            for entry in json["entries"].array! {
                let directoryEntry = DirectoryEntry()
                if let personId = entry["personId"].string , !personId.isEmpty {
                    directoryEntry.personId = personId
                }
                if let username = entry["username"].string , !username.isEmpty {
                    directoryEntry.username = username
                }
                if let displayName = entry["displayName"].string , !displayName.isEmpty {
                    directoryEntry.displayName = displayName
                }
                if let firstName = entry["firstName"].string , !firstName.isEmpty {
                    directoryEntry.firstName = firstName
                }
                if let middleName = entry["middleName"].string , !middleName.isEmpty {
                    directoryEntry.middleName = middleName
                }
                if let lastName = entry["lastName"].string , !lastName.isEmpty {
                    directoryEntry.lastName = lastName
                }
                if let nickName = entry["nickName"].string , !nickName.isEmpty {
                    directoryEntry.nickName = nickName
                }
                if let title = entry["title"].string , !title.isEmpty {
                    directoryEntry.title = title
                }
                if let office = entry["office"].string , !office.isEmpty {
                    directoryEntry.office = office
                }
                if let department = entry["department"].string , !department.isEmpty {
                    directoryEntry.department = department
                }
                if let phone = entry["phone"].string , !phone.isEmpty {
                    directoryEntry.phone = phone
                }
                if let mobile = entry["mobile"].string , !mobile.isEmpty {
                    directoryEntry.mobile = mobile
                }
                if let email = entry["email"].string , !email.isEmpty {
                    directoryEntry.email = email
                }
                if let street = entry["street"].string , !street.isEmpty {
                    directoryEntry.street = street.replacingOccurrences(of: "\\n", with: "\n")
                }
                if let room = entry["room"].string , !room.isEmpty {
                    directoryEntry.room = room
                }
                if let postOfficeBox = entry["postOfficeBox"].string , !postOfficeBox.isEmpty {
                    directoryEntry.postOfficeBox = postOfficeBox
                }
                if let city = entry["city"].string , !city.isEmpty {
                    directoryEntry.city = city
                }
                if let state = entry["state"].string , !state.isEmpty {
                    directoryEntry.state = state
                }
                if let postalCode = entry["postalCode"].string , !postalCode.isEmpty {
                    directoryEntry.postalCode = postalCode
                }
                if let country = entry["country"].string , !country.isEmpty {
                    directoryEntry.country = country
                }
                if let prefix = entry["prefix"].string , !prefix.isEmpty {
                    directoryEntry.prefix = prefix
                }
                if let suffix = entry["suffix"].string , !suffix.isEmpty {
                    directoryEntry.suffix = suffix
                }
                if let type = entry["type"].string , !type.isEmpty {
                    directoryEntry.type = type
                }
                if let imageUrl = entry["imageUrl"].string , !imageUrl.isEmpty {
                    directoryEntry.imageUrl = imageUrl
                }
                entries.append(directoryEntry)
            }
        }
        return entries
    }
}
