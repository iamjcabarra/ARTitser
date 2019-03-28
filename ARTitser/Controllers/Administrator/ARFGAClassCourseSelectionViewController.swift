//
//  ARFGAClassCourseSelectionViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 11/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD

protocol ARFGAClassCourseSelectionViewControllerDelegate: class {
    func requestRerenderDataForClassCourseUpdate()
}

class ARFGAClassCourseSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var dimmedView: UIView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var searchButton: UIButton!
    @IBOutlet var selectButton: UIButton!
    
    weak var delegate: ARFGAClassCourseSelectionViewControllerDelegate?
    
    var classId: Int64 = 0
    var isCreation = false
    var selectedCourseId: Int64 = 0
    
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
        self.navigationBar.topItem?.title = "Select Course"
        
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
        
        /// Request for list of courses
        self.reloadCourseList()
        
        /// Configure pull to refresh
        let action = #selector(self.refreshCourseList)
        self.tableRefreshControl = UIRefreshControl()
        self.tableRefreshControl.addTarget(self, action: action, for: .valueChanged)
        self.tableView.addSubview(self.tableRefreshControl)
        
        /// Configure table selection
        self.tableView.allowsSelection = true
        self.tableView.allowsMultipleSelection = false
        
        /// Configure search bar
        self.searchBar.placeholder = "Search Course"
        self.searchBar.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    /// Renders retrieved list of courses from database on the
    /// table view as the view has loaded.
    @objc fileprivate func reloadCourseList() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.arfDataManager.requestRetrieveCourses() { (result) in
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
    
    /// Renders retrieved list of courses from database on the
    /// table view as user pulls the table view.
    @objc fileprivate func refreshCourseList() {
        self.arfDataManager.requestRetrieveCourses() { (result) in
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
    
    /// Adds selection to deep copy class course
    /// and goes back to previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func selectButtonAction(_ sender: UIButton) {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        if self.selectedCourseId != 0 {
            self.arfDataManager.relateCourse(withId: self.selectedCourseId, toDeepCopyClassWithId: self.classId, completion: { (success) in
                if success {
                    DispatchQueue.main.async {
                        HUD.hide()
                        self.dismiss(animated: true, completion: { self.delegate?.requestRerenderDataForClassCourseUpdate() })
                    }
                }
                else {
                    DispatchQueue.main.async {
                        HUD.hide()
                        let subtitle = ARFConstants.message.DEFAULT_ERROR
                        HUD.flash(.labeledError(title: "Select Course", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                    }
                }
            })
        }
        else {
            let subtitle = "Please select a course to continue."
            HUD.flash(.labeledError(title: "Select Course", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
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
    /// requests for course list or search for specific
    /// courses.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        if (show) {
            var message = "No available course yet."
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
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.CLASS_COURSE_SELECTION, for: indexPath) as! ARFGAClassCourseSelectionTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ARFGAClassCourseSelectionTableViewCell, atIndexPath indexPath: IndexPath) {
        let courseObject = fetchedResultsController.object(at: indexPath) as! Course
        cell.courseImage.image = ARFConstants.image.GAV_COURSE
        cell.courseCodeLabel.text = courseObject.code!
        cell.courseCodeLabel.text = courseObject.code!
        cell.courseTitleLabel.text = courseObject.title!
        
        let selected = self.selectedCourseId == 0 ? false : self.selectedCourseId == courseObject.id ? true : false
        cell.statusSelectionImage.image = selected ? ARFConstants.image.GEN_RB_SELECTED : ARFConstants.image.GEN_RB_UNSELECTED
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let courseObject = fetchedResultsController.object(at: indexPath) as! Course
        self.selectedCourseId = courseObject.id == self.selectedCourseId ? 0 : courseObject.id
        self.reloadFetchedResultsController()
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.COURSE)
        fetchRequest.fetchBatchSize = 20
        
        if (self.searchKey != "") {
            let predicate = self.arfDataManager.predicate(forKeyPath: "searchString", containsValue: self.searchKey)
            fetchRequest.predicate = predicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "dateUpdated", ascending: true)
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
                    self.configureCell(cell as! ARFGAClassCourseSelectionTableViewCell, atIndexPath: indexPath)
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
