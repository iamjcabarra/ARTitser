//
//  ARFGCFileViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 27/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD

protocol ARFGCFileViewControllerDelegate: class {
    func selectedFile(withName name: String, andData data: Data)
}

class ARFGCFileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var selectButton: UIButton!
    
    weak var delegate: ARFGCFileViewControllerDelegate?
    var isCreation = false
    
    fileprivate var sandboxHelper = ARFSandboxHelper()
    fileprivate var subDirectoryPath = ""
    fileprivate var subDirectoryName = ""
    fileprivate var selectedFile: File? = nil
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = "Select Asset"
        
        /// Configure background color
        let backgroundColor = self.isCreation ? ARFConstants.color.GEN_CREATE_ACTION : ARFConstants.color.GEN_UPDATE_ACTION
        self.navigationBar.barTintColor = backgroundColor
        self.bottomView.backgroundColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Configure buttons
        self.closeButton.addTarget(self, action: #selector(self.closeButtonAction(_:)), for: .touchUpInside)
        self.selectButton.addTarget(self, action: #selector(self.selectButtonAction(_:)), for: .touchUpInside)
        
        /// Set subdirectory path
        self.subDirectoryName = ARFConstants.directoryName.TREASURES
        self.subDirectoryPath = self.sandboxHelper.makeSubdirectoryInDocumentsDirectory(withName: self.subDirectoryName)
        
        /// Manage files
        self.reloadFiles()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Reload Files
    
    /// Saves each details of file from the Treasures
    /// directory in core data.
    fileprivate func reloadFiles() {
        var files = [[String: Any]]()
        let contents = self.sandboxHelper.retrieveContentsOfDirectory(atPath: self.subDirectoryPath)
      
        for item in contents {
            let itemPath = (self.subDirectoryPath as NSString).appendingPathComponent(item)
            let itemDetails = self.sandboxHelper.retrieveAttributesOfFile(atPath: itemPath)
            let isDirectory = self.sandboxHelper.isItemAtPathADirectory(itemPath)
            let isInValidItem = item.lowercased().contains("ds_store")
            
            if !isDirectory && !isInValidItem {
                let fsfn = itemDetails[FileAttributeKey.systemFileNumber]
                let sdui = self.subDirectoryName
                let name = item
                let type = itemDetails[FileAttributeKey.type]
                let path = itemPath
                let size = itemDetails[FileAttributeKey.size]
                let date = itemDetails[FileAttributeKey.modificationDate]
                
                let dict = ["fsfn": fsfn ?? 0, "sdui": sdui, "name": name, "type": type!, "path": path, "size": size ?? 0, "date": date ?? Date()]
                files.append(dict as [String : Any])
            }
        }
        
        self.arfDataManager.saveFiles(files) { (success) in
            DispatchQueue.main.async(execute: {
                self.reloadFetchedResultsController()
            })
        }
    }
    
    // MARK: - Button Event Handlers
    
    /// Dismisses this view and returns to the previous
    /// view as user clicks on cancel button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func closeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Converts selected file to data. If succeeds, it
    /// then goes back to the treasure creation view
    /// sending the converted file.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func selectButtonAction(_ sender: UIButton) {
        if let file = self.selectedFile, let path = file.path, let name = file.name {
            let url = URL(fileURLWithPath: path)
            
            do {
                let data = try Data(contentsOf: url)
                self.dismiss(animated: true, completion: { self.delegate?.selectedFile(withName: name, andData: data) })
            }
            catch {
                let subtitle = ARFConstants.message.DEFAULT_ERROR
                HUD.flash(.labeledError(title: "", subtitle: subtitle), onView: nil, delay: 3.5, completion: nil)
            }
        }
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sectionCount = fetchedResultsController.sections?.count else { return 0 }
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionData = fetchedResultsController.sections?[section] else { return 0 }
        return sectionData.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.FILE, for: indexPath) as! ARFGCFileTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ARFGCFileTableViewCell, atIndexPath indexPath: IndexPath) {
        let fileObject = fetchedResultsController.object(at: indexPath) as! File
        let format = ARFConstants.timeFormat.CLIENT
        cell.fileNameLabel.text = fileObject.name!
        cell.fileModifiedDateLabel.text = self.arfDataManager.string(fromDate: fileObject.date ?? Date(), format: format)
        cell.fileSizeLabel.text = self.sandboxHelper.formattedStringSize(fileObject.size)
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedFile = fetchedResultsController.object(at: indexPath) as? File
        self.selectButton.shake()
        self.selectButton.flash()
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.FILE)
        fetchRequest.fetchBatchSize = 20
        
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
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
                    self.configureCell(cell as! ARFGCFileTableViewCell, atIndexPath: indexPath)
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
