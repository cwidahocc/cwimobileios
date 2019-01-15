//
//  GradesTableViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/12/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class GradesTableViewController : UITableViewController , NSFetchedResultsControllerDelegate, EllucianMobileLaunchableControllerProtocol {

    var module : Module!
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
    var initiallyEmpty = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.module?.name
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        fetchGrades()
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[0] as NSFetchedResultsSectionInfo
            let count = currentSection.numberOfObjects
            if count > 0 {
                self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: UITableViewScrollPosition.none)
                self.performSegue(withIdentifier: "Show Term", sender: nil)
            } else {
                initiallyEmpty = true
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendView("Grades List", moduleName: self.module?.name)
    }
    
    // MARK: data retrieval
    func fetchGrades() {
        let operation = GradesFetchOperation(module: module, view: self)

        
        if self.fetchedResultsController.fetchedObjects!.count <= 0 {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
            hud.label.text = loadingString
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        }
        
        OperationQueue.main.addOperation(operation)
    }
    
    //MARK: segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Term" {
            
            let detailController = (segue.destination as! UINavigationController).topViewController as! GradesTermTableViewController
            let term = fetchedResultsController.object(at: self.tableView.indexPathForSelectedRow!)
            detailController.term = term
            detailController.module = self.module
        }
    }
    
    // MARK: fetch
    var fetchedResultsController: NSFetchedResultsController<GradeTerm> {
        // return if already initialized
        if self._fetchedResultsController != nil {
            return self._fetchedResultsController!
        }
        let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
        
        let request = NSFetchRequest<GradeTerm>(entityName: "GradeTerm")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        self._fetchedResultsController = aFetchedResultsController
        
        do {
            try self._fetchedResultsController!.performFetch()
            
        } catch let error {
            print("fetch error: \(error)")
        }
        
        return self._fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<GradeTerm>?
    
    //MARK :UITable
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as NSFetchedResultsSectionInfo
            return currentSection.numberOfObjects
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.fetchedResultsController.fetchedObjects!.count > 0 {

            let cell = tableView.dequeueReusableCell(withIdentifier: "Term Cell", for: indexPath) as UITableViewCell
            let term = fetchedResultsController.object(at: indexPath)
            
            let titleLabel = cell.viewWithTag(1) as! UILabel
            
            titleLabel.text = term.name
            return cell
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "No Grades Cell", for: indexPath) as UITableViewCell
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type{
        case NSFetchedResultsChangeType.insert:
            self.tableView.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.top)
            break
        case NSFetchedResultsChangeType.delete:
            self.tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.left)
            break
        case NSFetchedResultsChangeType.update:
            self.tableView.cellForRow(at: indexPath!)?.setNeedsLayout()
            break
        default:
            return
        }
    }

    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
        
        DispatchQueue.main.async {
            self._fetchedResultsController = nil
            self.tableView.reloadData()
            if self.initiallyEmpty {
                let currentSection = self.fetchedResultsController.sections![0] as NSFetchedResultsSectionInfo
                let count = currentSection.numberOfObjects
                if count > 0 {
                    self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: UITableViewScrollPosition.none)
                    self.performSegue(withIdentifier: "Show Term", sender: nil)
                }
            }
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}
