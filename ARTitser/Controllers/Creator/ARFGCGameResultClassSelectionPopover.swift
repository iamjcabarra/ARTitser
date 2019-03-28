//
//  ARFGCGameResultClassSelectionPopover.swift
//  ARFollow
//
//  Created by Julius Abarra on 13/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD

protocol ARFGCGameResultClassSelectionPopoverDelegate: class {
    func selectedClass(withId id: Int64, andCode code: String)
}

class ARFGCGameResultClassSelectionPopover: UITableViewController, NSFetchedResultsControllerDelegate {
    
    weak var delegate: ARFGCGameResultClassSelectionPopoverDelegate?
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Request for list of classes
        self.reloadClassList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    /// Renders retrieved list of classes from database on the
    /// table view as the view has loaded.
    @objc fileprivate func reloadClassList() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.arfDataManager.requestRetrieveClasses { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    HUD.hide()
                    self.reloadFetchedResultsController()
                }
            }
            else {
                DispatchQueue.main.async {
                    HUD.hide()
                    let subtitle = result!["message"] as! String
                    HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                }
            }
        }
    }

    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let sectionCount = fetchedResultsController.sections?.count else { return 0 }
        return sectionCount
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionData = fetchedResultsController.sections?[section] else { return 0 }
        return sectionData.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let classObject = fetchedResultsController.object(at: indexPath) as! Class
        cell.textLabel?.text = classObject.code!
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let classObject = fetchedResultsController.object(at: indexPath) as! Class
        self.dismiss(animated: true) { self.delegate?.selectedClass(withId: classObject.id, andCode: classObject.code ?? "") }
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.CLASS)
        fetchRequest.fetchBatchSize = 20
        
        let predicate = self.arfDataManager.predicate(forKeyPath: "creatorId", exactValue: "\(self.arfDataManager.loggedUserId)")
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: ctx!, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        
        _fetchedResultsController = frc
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch {
            abort()
        }
        
        return _fetchedResultsController!
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.tableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath {
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    self.configureCell(cell as! ARFGCGameClassSelectionTableViewCell, atIndexPath: indexPath)
                }
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func reloadFetchedResultsController() {
        self._fetchedResultsController = nil
        self.tableView.reloadData()
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
}
