//
//  GradesFetchOperation.swift
//  Mobile
//
//  Created by Jason Hocker on 9/10/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class GradesFetchOperation : Operation {
    
    private var module : Module?
    private var view : UIViewController?
    
    let dateFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    let datetimeFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    init (module: Module?, view: UIViewController?) {
        self.module = module
        self.view = view
    }
    
    override func main() {
        
        if let userid = CurrentUser.sharedInstance.userid {
            let urlBase = self.module?.property(forKey: "grades")
            let urlString = "\(urlBase!)/\(userid.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)"
            
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.parent = self.module?.managedObjectContext
            privateContext.undoManager = nil
            
            privateContext.perform { () -> Void in
                
                do {
                    let authenticatedRequest = AuthenticatedRequest()
                    if let responseData = authenticatedRequest.requestURL(URL(string: urlString), fromView: self.view) {
                    let json = JSON(data: responseData)
                    
                    var previousTerms = [GradeTerm]()
                    var existingTerms = [GradeTerm]()
                    var updatedPrivateContext = false
                    
                    let termRequest = NSFetchRequest<GradeTerm>(entityName: "GradeTerm")
                    let oldObjects = try privateContext.fetch(termRequest)
                    for oldObject in oldObjects {
                        previousTerms.append(oldObject)
                    }
                    
                    if json["terms"].array != nil {
                        for termJson in json["terms"].array! {
                            
                            let termId = termJson["id"].string;
                            var gradeTerm : GradeTerm
                            
                            let filteredArray = previousTerms.filter({
                                let gradeTerm = $0 as GradeTerm
                                return gradeTerm.termId == termId;
                            })
                            if filteredArray.count > 0 {
                                gradeTerm = filteredArray[0]
                                existingTerms.append(gradeTerm)
                            } else {
                                gradeTerm = NSEntityDescription.insertNewObject(forEntityName: "GradeTerm", into: privateContext) as! GradeTerm
                                gradeTerm.termId = termJson["id"].string
                                gradeTerm.name = termJson["name"].string
                                gradeTerm.startDate = self.dateFormatter.date(from: termJson["startDate"].string!)
                                gradeTerm.endDate = self.dateFormatter.date(from: termJson["endDate"].string!)
                            }
                            
                            var previousCourses = [GradeCourse]()
                            var existingCourses = [GradeCourse]()
                            
                            for oldObject in gradeTerm.courses {
                                previousCourses.append(oldObject as! GradeCourse)
                            }
                            
                            for courseJson in termJson["sections"].array! {
                                
                                let sectionId = courseJson["sectionId"].string;
                                var gradeCourse : GradeCourse
                                
                                let filteredArray = previousCourses.filter({
                                    let gradeCourse = $0 as GradeCourse
                                    return gradeCourse.sectionId == sectionId;
                                })
                                if filteredArray.count > 0 {
                                    gradeCourse = filteredArray[0]
                                    existingCourses.append(gradeCourse)
                                } else {
                                    gradeCourse = NSEntityDescription.insertNewObject(forEntityName: "GradeCourse", into: privateContext) as! GradeCourse
                                    gradeCourse.sectionId = courseJson["sectionId"].string
                                    gradeCourse.courseName = courseJson["courseName"].string
                                    if let sectionTitle = courseJson["sectionTitle"].string , sectionTitle != "" {
                                        gradeCourse.sectionTitle = sectionTitle
                                    }
                                    if let courseSectionNumber = courseJson["courseSectionNumber"].string , courseSectionNumber != "" {
                                        gradeCourse.courseSectionNumber = courseSectionNumber
                                    }
                                    //rdar://10114310
                                    gradeTerm.addCoursesObject(gradeCourse)
                                    gradeCourse.term = gradeTerm
                                }
                                
                                var previousGrades = [Grade]()
                                var existingGrades = [Grade]()
                                for oldObject in gradeCourse.grades {
                                    previousGrades.append(oldObject as! Grade)
                                }
                                
                                for gradeJson in courseJson["grades"].array! {
                                    let name = gradeJson["name"].string;
                                    let value = gradeJson["value"].string
                                    var grade : Grade
                                    
                                    let filteredArray = previousGrades.filter({
                                        let grade = $0 as Grade
                                        return grade.name == name && grade.value == value;
                                    })
                                    if filteredArray.count > 0 {
                                        grade = filteredArray[0]
                                        existingGrades.append(grade)
                                    } else {
                                        grade = NSEntityDescription.insertNewObject(forEntityName: "Grade", into: privateContext) as! Grade
                                        grade.name = gradeJson["name"].string
                                        grade.value = gradeJson["value"].string
                                        if let updated = gradeJson["updated"].string , updated != "" {
                                            grade.lastUpdated = self.datetimeFormatter.date(from: updated)
                                        }
                                        gradeCourse.addGradesObject(grade)
                                        grade.course = gradeCourse
                                    }
                                }
                                for oldObject in previousGrades {
                                    if !existingGrades.contains(oldObject) {
                                        privateContext.delete(oldObject)
                                        updatedPrivateContext = true
                                    }
                                }
                            }
                            
                            for oldObject in previousCourses {
                                if !existingCourses.contains(oldObject) {
                                    privateContext.delete(oldObject)
                                    updatedPrivateContext = true
                                }
                            }
                        }
                    }
                    for oldObject in previousTerms {
                        if !existingTerms.contains(oldObject) {
                            privateContext.delete(oldObject)
                            updatedPrivateContext = true
                        }
                    }
                    try privateContext.save()
                    
                    privateContext.parent?.perform({
                        do {
                            try privateContext.parent?.save()
                            if updatedPrivateContext {
                                DispatchQueue.main.async {
                                    (self.view as? GradesTermTableViewController)?.tableView.reloadData()
                                }
                            }
                        } catch let error {
                            print (error)
                        }
                    })
                    } else {
                        if let view = self.view {
                            DispatchQueue.main.async {
                                let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment:"title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment:"message when data cannot load due to a poor netwrok connection"),    preferredStyle: .alert)
                                let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: UIAlertActionStyle.default)
                                alertController.addAction(alertAction)
                                view.present(alertController, animated: true)
                            }
                        }
                    }
                    if let view = self.view {
                        DispatchQueue.main.async(execute: {() -> Void in
                            MBProgressHUD.hide(for: view.view, animated: true)
                        })
                    }
                } catch let error {
                    print (error)
                    if let view = self.view {
                        DispatchQueue.main.async(execute: {() -> Void in
                            MBProgressHUD.hide(for: view.view, animated: true)
                        })
                    }
                }
                
            }
        }
    }
}
