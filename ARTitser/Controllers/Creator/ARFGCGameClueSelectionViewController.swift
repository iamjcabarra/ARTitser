//
//  ARFGCGameClueSelectionViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 03/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD

protocol ARFGCGameClueSelectionViewControllerDelegate: class {
    func requestRerenderDataForGameCluesUpdate()
}

class ARFGCGameClueSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var dimmedView: UIView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var selectButton: UIButton!
    
    weak var delegate: ARFGCGameClueSelectionViewControllerDelegate?
    
    var gameId: Int64 = 0
    var isCreation = false
    var selectedClues: [Int64]? = nil
    
    fileprivate var tableRefreshControl: UIRefreshControl!
    fileprivate var searchKey = ""
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = "Select Question"
        
        /// Configure background color
        let backgroundColor = self.isCreation ? ARFConstants.color.GEN_CREATE_ACTION : ARFConstants.color.GEN_UPDATE_ACTION
        self.navigationBar.barTintColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Hide empty place holder by default
        self.shouldShowEmptyPlaceholderView(false)
        
        /// Hide by default
        self.dimmedView.isHidden = true
        
        /// Configure tap recognizer for dimmedView
        let cancelSearchOperation = #selector(self.cancelSearchOperation(_:))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: cancelSearchOperation)
        self.dimmedView.addGestureRecognizer(tapGestureRecognizer)
        
        /// Configure buttons
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        self.searchButton.addTarget(self, action: #selector(self.searchButtonAction(_:)), for: .touchUpInside)
        self.selectButton.addTarget(self, action: #selector(self.selectButtonAction(_:)), for: .touchUpInside)
        
        /// Request for list of clues
        self.reloadClueList()
        
        /// Configure pull to refresh
        let action = #selector(self.refreshClueList)
        self.tableRefreshControl = UIRefreshControl()
        self.tableRefreshControl.addTarget(self, action: action, for: .valueChanged)
        self.tableView.addSubview(self.tableRefreshControl)
        
        /// Configure table selection
        self.tableView.allowsSelection = true
        
        /// Configure search bar
        self.searchBar.placeholder = "Search Question"
        self.searchBar.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    /// Renders retrieved list of clues from database on the
    /// table view as the view has loaded.
    @objc fileprivate func reloadClueList() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.arfDataManager.requestRetrieveClues(forUserWithId: "\(self.arfDataManager.loggedUserId)") { (result) in
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
    
    /// Renders retrieved list of clues from database on the
    /// table view as user pulls the table view.
    @objc fileprivate func refreshClueList() {
        self.arfDataManager.requestRetrieveClues(forUserWithId: "\(self.arfDataManager.loggedUserId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    self.tableRefreshControl.endRefreshing()
                    self.reloadFetchedResultsController()
                }
            }
            else {
                DispatchQueue.main.async {
                    self.tableRefreshControl.endRefreshing()
                    let subtitle = result!["message"] as! String
                    HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                }
            }
        }
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Shows search bar on the navigation bar as user
    /// clicks on search button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func searchButtonAction(_ sender: UIButton) {
        self.navigationBar.topItem?.titleView = self.searchBar
        self.searchBar.becomeFirstResponder()
    }
    
    /// Adds selection to deep copy game clue and
    /// goes back to previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func selectButtonAction(_ sender: UIButton) {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        if self.selectedClues == nil || self.selectedClues?.count == 0 {
            let title = "Select Question"
            let subtitle = "Please select at least one question to continue."
            HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
        }
        else {
            self.arfDataManager.relateClues(withIds: self.selectedClues!, toDeepCopyGameWithId: self.gameId, completion: { (success) in
                if success {
                    DispatchQueue.main.async {
                        HUD.hide()
                        self.dismiss(animated: true, completion: { self.delegate?.requestRerenderDataForGameCluesUpdate() })
                    }
                }
                else {
                    DispatchQueue.main.async {
                        HUD.hide()
                        let title = "Select Question"
                        let subtitle = ARFConstants.message.DEFAULT_ERROR
                        HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                    }
                }
            })
        }
    }
    
    // MARK: - Tap Gesture Recognizer
    
    /// Cancels search operation as user taps on dimmed
    /// view.
    ///
    /// - parameter sender: A UITapGestureRecognizer
    @objc fileprivate func cancelSearchOperation(_ sender: UITapGestureRecognizer) {
        self.navigationBar.topItem?.titleView = nil
        self.dimmedView.isHidden = true
        self.view.endEditing(true)
        self.searchBar.text = self.searchKey
    }
    
    // MARK: - Empty Placeholder View
    
    /// Shows or hides empty place holder view as user
    /// requests for clue list or search for specific
    /// clues.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        if (show) {
            var message = "No available question yet."
            if (self.searchBar.text != "") { message = "No results found for \"\(self.searchKey)\"." }
            self.emptyPlaceholderLabel.text = message
        }
        
        self.emptyPlaceholderView.isHidden = !show
        self.tableView.isHidden = show
    }
    
    // MARK: - Search Bar Delegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.dimmedView.isHidden = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText == "") {
            self.searchKey = searchText
            self.reloadFetchedResultsController()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchKey = searchBar.text!
        self.reloadFetchedResultsController()
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.text = self.searchKey
        self.navigationBar.topItem?.titleView = nil
        self.dimmedView.isHidden = true
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sectionCount = fetchedResultsController.sections?.count else { return 0 }
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionData = fetchedResultsController.sections?[section] else { return 0 }
        self.shouldShowEmptyPlaceholderView((sectionData.numberOfObjects > 0) ? false : true)
        return sectionData.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.GAME_CLUE_SELECTION, for: indexPath) as! ARFGCGameClueSelectionTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ARFGCGameClueSelectionTableViewCell, atIndexPath indexPath: IndexPath) {
        let clueObject = fetchedResultsController.object(at: indexPath) as! Clue
        let type1Image = ARFConstants.image.GCV_CLUE_TYPE_ID
        let type2Image = ARFConstants.image.GCV_CLUE_TYPE_MC
        let type3Image = ARFConstants.image.GCV_CLUE_TYPE_TF
        
        cell.clueImage.image = ARFConstants.image.GCV_CLUE
        cell.clueLabel.text = clueObject.clue!
        cell.clueRiddleLabel.text = clueObject.riddle!
        cell.clueActPointsLabel.text = "\(clueObject.points)"
        cell.cluePointsLabel.text = clueObject.points > 1 ? "Points" : "Point"
        cell.clueTypeImage.image = clueObject.type == 1 ? type1Image : clueObject.type == 2 ? type2Image : type3Image
        
        let selected = self.selectedClues == nil ? false : self.selectedClues!.contains(clueObject.id) ? true : false
        cell.selectionStatusImage.image = selected ? ARFConstants.image.GEN_CB_SELECTED : ARFConstants.image.GEN_CB_UNSELECTED
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let clueObject = fetchedResultsController.object(at: indexPath) as! Clue
        
        if self.selectedClues == nil || self.selectedClues?.count == 0 {
            self.selectedClues = [clueObject.id]
        }
        else {
            if !self.selectedClues!.contains(clueObject.id) { self.selectedClues!.append(clueObject.id) }
            else { if let index = self.selectedClues!.index(of: clueObject.id) { self.selectedClues?.remove(at: index) } }
        }
        
        self.reloadFetchedResultsController()
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.CLUE)
        fetchRequest.fetchBatchSize = 20
        
        if (self.searchKey != "") {
            let predicate = self.arfDataManager.predicate(forKeyPath: "searchString", containsValue: self.searchKey)
            fetchRequest.predicate = predicate
        }
        
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
                    self.configureCell(cell as! ARFGCGameClueSelectionTableViewCell, atIndexPath: indexPath)
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
