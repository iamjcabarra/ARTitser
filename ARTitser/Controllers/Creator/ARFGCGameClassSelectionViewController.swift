//
//  ARFGCGameClassSelectionViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 04/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD

class ARFGCGameClassSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var dimmedView: UIView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var deployButton: UIButton!
    
    var gameId: Int64 = 0
    var gameName = ""
    var selectedClasses: [Int64]? = nil
    
    fileprivate var tableRefreshControl: UIRefreshControl!
    fileprivate var searchKey = ""
    fileprivate var deployedClasses: [Int64]? = nil

    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = "Deploy \(self.gameName)"
        
        /// Configure background color
        let backgroundColor = ARFConstants.color.GAV_NAV_DASHBOARD
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
        self.deployButton.addTarget(self, action: #selector(self.deployButtonAction(_:)), for: .touchUpInside)
        
        /// Request for list of classes
        self.reloadClassList()
        
        /// Configure pull to refresh
        let action = #selector(self.refreshClassList)
        self.tableRefreshControl = UIRefreshControl()
        self.tableRefreshControl.addTarget(self, action: action, for: .valueChanged)
        self.tableView.addSubview(self.tableRefreshControl)
        
        /// Configure table selection
        self.tableView.allowsSelection = true
        
        /// Configure search bar
        self.searchBar.placeholder = "Search Class"
        self.searchBar.delegate = self
        
        /// Set deployed classes
        self.deployedClasses = self.selectedClasses
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
    
    /// Renders retrieved list of classes from database on the
    /// table view as user pulls the table view.
    @objc fileprivate func refreshClassList() {
        self.arfDataManager.requestRetrieveClasses { (result) in
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
    
    /// Requests game deployment and goes back to
    /// previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func deployButtonAction(_ sender: UIButton) {
        if self.selectedClasses == nil || self.selectedClasses?.count == 0 {
            if self.deployedClasses != nil && self.deployedClasses!.count > 0 {
                HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
                
                var classIds = ""
                for classId in self.deployedClasses! { classIds = "\(classIds == "" ? "" : "\(classIds),")\(classId)" }
                let body: [String: Any] = ["classIds": classIds]
                
                self.arfDataManager.requestUndeployGame(withId: "\(self.gameId)", body: body, completion: { (result) in
                    let status = result!["status"] as! Int
                    
                    if status == 0 {
                        DispatchQueue.main.async {
                            HUD.hide()
                            
                            let subtitle = "\(self.gameName) has been successfully undeployed from unselected \(self.deployedClasses!.count > 1 ? "classes" : "class")."
                            HUD.flash(.label(subtitle), onView: nil, delay: 3.5, completion: { (success) in
                                self.dismiss(animated: true, completion: nil)
                            })
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = ARFConstants.message.DEFAULT_ERROR
                            HUD.flash(.labeledError(title: "", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                        }
                    }
                })
            }
            else {
                let subtitle = "Please select at leaset one class where to deploy \(self.gameName) to continue."
                HUD.flash(.label(subtitle), onView: nil, delay: 3.5, completion: { (success) in })
            }
        }
        else {
            HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
            
            var classIds = ""
            for classId in self.selectedClasses! { classIds = "\(classIds == "" ? "" : "\(classIds),")\(classId)" }
            let body: [String: Any] = ["classIds": classIds]
            
            self.arfDataManager.requestDeployGame(withId: "\(self.gameId)", body: body, completion: { (result) in
                let status = result!["status"] as! Int
                
                if status == 0 {
                    var undeployClassIds = ""
                    
                    if self.deployedClasses != nil {
                        for classId in self.deployedClasses! {
                            if !self.selectedClasses!.contains(classId) {
                               undeployClassIds = "\(undeployClassIds == "" ? "" : "\(undeployClassIds),")\(classId)"
                            }
                        }
                    }
                    
                    if undeployClassIds != "" {
                        let undeployBody: [String: Any] = ["classIds": undeployClassIds]
                        self.arfDataManager.requestUndeployGame(withId: "\(self.gameId)", body: undeployBody, completion: { (result) in
                            let status = result!["status"] as! Int
                            
                            if status == 0 {
                                DispatchQueue.main.async {
                                    HUD.hide()
                                    
                                    let subtitle = "\(self.gameName) has been successfully deployed to selected \(self.selectedClasses!.count > 1 ? "classes" : "class") and undeployed from unselected \(self.deployedClasses!.count > 1 ? "classes" : "class")."
                                    HUD.flash(.label(subtitle), onView: nil, delay: 3.5, completion: { (success) in
                                        self.dismiss(animated: true, completion: nil)
                                    })
                                }
                            }
                            else {
                                DispatchQueue.main.async {
                                    HUD.hide()
                                    let subtitle = ARFConstants.message.DEFAULT_ERROR
                                    HUD.flash(.labeledError(title: "", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                                }
                            }
                        })
                    }
                    else {
                        DispatchQueue.main.async {
                            HUD.hide()
                            
                            let subtitle = "\(self.gameName) has been successfully deployed to selected \(self.selectedClasses!.count > 1 ? "classes" : "class")."
                            HUD.flash(.label(subtitle), onView: nil, delay: 3.5, completion: { (success) in
                                self.dismiss(animated: true, completion: nil)
                            })
                        }
                    }
                }
                else {
                    DispatchQueue.main.async {
                        HUD.hide()
                        let subtitle = ARFConstants.message.DEFAULT_ERROR
                        HUD.flash(.labeledError(title: "", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
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
    /// requests for class list or search for specific
    /// classes.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        if (show) {
            var message = "You are not assigned to any class yet."
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
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.GAME_CLASS_SELECTION, for: indexPath) as! ARFGCGameClassSelectionTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ARFGCGameClassSelectionTableViewCell, atIndexPath indexPath: IndexPath) {
        let classObject = fetchedResultsController.object(at: indexPath) as! Class
        
        cell.classImage.image = ARFConstants.image.GAV_CLASS
        cell.classCodeLabel.text = classObject.code!
        cell.classDescriptionLabel.text = classObject.aClassDescription!
        cell.classScheduleLabel.text = classObject.schedule!
        
        let size = classObject.players != nil ? classObject.players!.count : 0
        cell.actClassSizeLabel.text = "\(size)"
        cell.classSizeLabel.text = "\(size > 1 ? "Students" : "Student")"
        
        let selected = self.selectedClasses == nil ? false : self.selectedClasses!.contains(classObject.id) ? true : false
        cell.selectionStatusImage.image = selected ? ARFConstants.image.GEN_CB_SELECTED : ARFConstants.image.GEN_CB_UNSELECTED
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let classObject = fetchedResultsController.object(at: indexPath) as! Class
        
        if self.selectedClasses == nil || self.selectedClasses?.count == 0 {
            self.selectedClasses = [classObject.id]
        }
        else {
            if !self.selectedClasses!.contains(classObject.id) { self.selectedClasses!.append(classObject.id) }
            else { if let index = self.selectedClasses!.index(of: classObject.id) { self.selectedClasses?.remove(at: index) } }
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
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.CLASS)
        fetchRequest.fetchBatchSize = 20
        
        if (self.searchKey != "") {
            let predicateA = self.arfDataManager.predicate(forKeyPath: "creatorId", exactValue: "\(self.arfDataManager.loggedUserId)")
            let predicateB = self.arfDataManager.predicate(forKeyPath: "searchString", containsValue: self.searchKey)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateA, predicateB])
        }
        else {
            let predicate = self.arfDataManager.predicate(forKeyPath: "creatorId", exactValue: "\(self.arfDataManager.loggedUserId)")
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
