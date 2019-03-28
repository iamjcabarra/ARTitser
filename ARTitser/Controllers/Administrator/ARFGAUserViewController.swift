//
//  ARFGAUserViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 23/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD
import SDWebImage

class ARFGAUserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate, ARFGAUserCreationViewControllerDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var dimmedView: UIView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!

    var loggedUserId: Int64 = 0
    
    fileprivate var tableRefreshControl: UIRefreshControl!
    fileprivate var searchKey = ""
    fileprivate var isAscending = true
    fileprivate var userCount = 1
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Empty navigation bar title by default
        self.title = ""
        
        /// Hide empty place holder by default
        self.shouldShowEmptyPlaceholderView(false)
        
        /// Hide by default
        self.dimmedView.isHidden = true
        
        /// Configure tap recognizer for dimmedView
        let cancelSearchOperation = #selector(self.cancelSearchOperation(_:))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: cancelSearchOperation)
        self.dimmedView.addGestureRecognizer(tapGestureRecognizer)
        
        /// Request for list of users
        self.reloadUserList()
        
        /// Configure pull to refresh
        let action = #selector(self.refreshUserList)
        self.tableRefreshControl = UIRefreshControl()
        self.tableRefreshControl.addTarget(self, action: action, for: .valueChanged)
        self.tableView.addSubview(self.tableRefreshControl)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Customize navigation
        self.customizeNavigationBar()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    /// Renders retrieved list of users from database on the
    /// table view as the view has loaded.
    @objc fileprivate func reloadUserList() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.arfDataManager.requestRetrieveUsers() { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let count = result!["count"] as! Int
                    self.userCount = count - 1
                    self.title = "Users (\(self.userCount > 0 ? self.userCount : 0))"
                    
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
    
    /// Renders retrieved list of users from database on the
    /// table view as user pulls the table view.
    @objc fileprivate func refreshUserList() {
        self.arfDataManager.requestRetrieveUsers() { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let count = result!["count"] as! Int
                    self.userCount = count - 1
                    self.title = "Users (\(self.userCount > 0 ? self.userCount : 0))"
                    
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
    
    // MARK: - Custom Navigation Bar
    
    /// Customizes navigation controller's navigation
    /// bar.
    fileprivate func customizeNavigationBar() {
        /// Configure navigation bar
        self.navigationController?.navigationBar.barTintColor = ARFConstants.color.GAV_NAV_USR_MOD
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        
        /// Configure add button
        let addButton = UIButton(type: UIButtonType.custom)
        addButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        addButton.showsTouchWhenHighlighted = true
        addButton.setImage(ARFConstants.image.GAV_ADD_USER, for: UIControlState())
        let addButtonAction = #selector(self.addButtonAction(_:))
        addButton.addTarget(self, action: addButtonAction, for: .touchUpInside)
        
        /// Configure custom back button
        let customBackButton = UIButton(type: UIButtonType.custom)
        customBackButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        customBackButton.showsTouchWhenHighlighted = true
        customBackButton.setImage(ARFConstants.image.GEN_CHEVRON, for: UIControlState())
        let customBackButtonAction = #selector(self.customBackButtonAction(_:))
        customBackButton.addTarget(self, action: customBackButtonAction, for: .touchUpInside)
        
        /// Add buttons to the left navigation bar
        let addButtonItem = UIBarButtonItem(customView: addButton)
        let customBackButtonItem = UIBarButtonItem(customView: customBackButton)
        self.navigationItem.leftBarButtonItems = [customBackButtonItem, addButtonItem]
        
        /// Configure search button
        let searchButton = UIButton(type: UIButtonType.custom)
        searchButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        searchButton.showsTouchWhenHighlighted = true
        searchButton.setImage(ARFConstants.image.GEN_SEARCH, for: UIControlState())
        let searchButtonAction = #selector(self.searchButtonAction(_:))
        searchButton.addTarget(self, action: searchButtonAction, for: .touchUpInside)
        
        /// Configure sort button
        let sortButton = UIButton(type: UIButtonType.custom)
        sortButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        sortButton.showsTouchWhenHighlighted = true
        sortButton.setImage(ARFConstants.image.GEN_SORT, for: UIControlState())
        let sortButtonAction = #selector(self.sortButtonAction(_:))
        sortButton.addTarget(self, action: sortButtonAction, for: .touchUpInside)
        
        /// Add buttons to the right navigation bar
        let sortButtonItem = UIBarButtonItem(customView: sortButton)
        let searchButtonItem = UIBarButtonItem(customView: searchButton)
        self.navigationItem.rightBarButtonItems = [sortButtonItem, searchButtonItem]
        
        /// Configure search bar
        self.searchBar.placeholder = "Search User"
        self.searchBar.delegate = self
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func customBackButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /// Presents user details view if deep copying of
    /// user object succeeded where user can create a
    /// new user.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func addButtonAction(_ sender: UIButton) {
        self.arfDataManager.deepCopyUserObject(nil, owner: self.loggedUserId, isCreation: true) { (result) in
            if result != nil {
                DispatchQueue.main.async {
                    let user = result!["user"] as! DeepCopyUser
                    let data: [String: Any] = ["userId": 0, "user": user, "isCreation": true]
                    self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GAV_USER_CREATION_VIEW, sender: data)
                }
            }
            else {
                DispatchQueue.main.async {
                    let subtitle = ARFConstants.message.DEFAULT_ERROR
                    HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                }
            }
        }
    }
    
    /// Shows search bar on the navigation bar as user
    /// clicks on search button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func searchButtonAction(_ sender: UIButton) {
        self.navigationItem.titleView = self.searchBar
        self.searchBar.becomeFirstResponder()
    }
    
    /// Switches sorting immediate variable and reloads
    /// data on table view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func sortButtonAction(_ sender: UIButton) {
        self.isAscending = self.isAscending ? false : true
        self.reloadFetchedResultsController()
    }
    
    // MARK: - Tap Gesture Recognizer
    
    /// Cancels search operation as user taps on dimmed
    /// view.
    ///
    /// - parameter sender: A UITapGestureRecognizer
    @objc fileprivate func cancelSearchOperation(_ sender: UITapGestureRecognizer) {
        self.navigationItem.titleView = nil
        self.dimmedView.isHidden = true
        self.view.endEditing(true)
        self.searchBar.text = self.searchKey
    }

    // MARK: - Empty Placeholder View
    
    /// Shows or hides empty place holder view as user
    /// requests for user list or search for specific
    /// users.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        var shouldShow = show
        if (self.searchBar.text == "") { shouldShow = self.userCount > 0 ? false : true }
        
        if (shouldShow) {
            var message = "No available user yet."
            if (self.searchBar.text != "") { message = "No results found for \"\(self.searchKey)\"." }
            self.emptyPlaceholderLabel.text = message
        }
        
        self.emptyPlaceholderView.isHidden = !shouldShow
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
        self.navigationItem.titleView = nil
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
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.USER, for: indexPath) as! ARFGAUserTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ARFGAUserTableViewCell, atIndexPath indexPath: IndexPath) {
        let userObject = fetchedResultsController.object(at: indexPath) as! User
        let firstName = userObject.firstName!
        let middleName = userObject.middleName!
        let lastName = userObject.lastName!
        let type = userObject.type
        let dateCreated = userObject.dateCreated!
        let imageUrl = userObject.imageUrl!
        
        cell.nameLabel.text = middleName == "" ? "\(firstName) \(lastName)" : "\(firstName) \(middleName) \(lastName)"
        cell.userTypeImage.image = type == 0 ? ARFConstants.image.GEN_ADMINISTRATOR : type == 1 ? ARFConstants.image.GEN_CREATOR : ARFConstants.image.GEN_PLAYER
        cell.extraLabel.text = "Member since \(self.arfDataManager.string(fromDate: dateCreated, format: "MMM. dd, yyyy"))"
        
        cell.userImage.sd_setImage(with: URL(string: imageUrl), completed: { (image, error, type, url) in
            cell.userImage.image = image != nil ? image! : ARFConstants.image.GEN_UNKNOWN_USER
        })
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userObject = fetchedResultsController.object(at: indexPath) as! User
        let data: [String: Any] = ["user": userObject]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GAV_USER_DETAILS_VIEW, sender: data)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let userObject = fetchedResultsController.object(at: indexPath) as! User
        
        let updateAction = UIContextualAction(style: .normal, title: "", handler: { (action: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            self.arfDataManager.deepCopyUserObject(userObject, owner: self.loggedUserId, isCreation: false, completion: { (result) in
                if result != nil {
                    DispatchQueue.main.async {
                        let user = result!["user"] as! DeepCopyUser
                        let data: [String: Any] = ["user": user, "isCreation": false]
                        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GAV_USER_CREATION_VIEW, sender: data)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        let subtitle = ARFConstants.message.DEFAULT_ERROR
                        HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                    }
                }
            })
            
            success(true)
        })
        
        let deleteAction = UIContextualAction(style: .normal, title: "", handler: { (action: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            let fullName = userObject.middleName! == "" ? "\(userObject.firstName!) \(userObject.lastName!)" : "\(userObject.firstName!) \(userObject.middleName!) \(userObject.lastName!)"
            let message = "Are you sure you want to delete \"\(fullName)\"?"
            let alert = UIAlertController(title: "Delete User", message: message, preferredStyle: .alert)
            
            let posAction = UIAlertAction(title: "Yes", style: .default) { (Alert) -> Void in
                HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
                
                self.arfDataManager.requestDeleteUser(withId: "\(userObject.id)", completion: { (result) in
                    let status = result!["status"] as! Int
                    
                    if status == 0 {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = result!["message"] as! String
                            HUD.flash(.labeledSuccess(title: "Delete User", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                                self.reloadUserList()
                                alert.dismiss(animated: true, completion: nil)
                            })
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = result!["message"] as! String
                            HUD.flash(.labeledError(title: "Delete User", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                                alert.dismiss(animated: true, completion: nil)
                            })
                        }
                    }
                })
            }
            
            let negAction = UIAlertAction(title: "No", style: .cancel) { (Alert) -> Void in
                DispatchQueue.main.async(execute: { alert.dismiss(animated: true, completion: nil) })
            }
            
            alert.addAction(posAction)
            alert.addAction(negAction)
            self.present(alert, animated: true, completion: nil)
            
            success(true)
        })
        
        updateAction.image = ARFConstants.image.GEN_UPDATE_MAROON
        updateAction.backgroundColor = .orange
        
        deleteAction.image = ARFConstants.image.GEN_DELETE
        deleteAction.backgroundColor = .red
        
        return UISwipeActionsConfiguration(actions: [deleteAction, updateAction])
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.USER)
        fetchRequest.fetchBatchSize = 20
        
        if (self.searchKey != "") {
            let predicateA = self.arfDataManager.predicate(forKeyPath: "id", notValue: "\(self.arfDataManager.loggedUserId)")
            let predicateB = self.arfDataManager.predicate(forKeyPath: "searchString", containsValue: self.searchKey)
            let predicateC = self.arfDataManager.predicate(forKeyPath: "isForApproval", notValue: "1")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateA, predicateB, predicateC])
        }
        else {
            let predicateA = self.arfDataManager.predicate(forKeyPath: "id", notValue: "\(self.arfDataManager.loggedUserId)")
            let predicateB = self.arfDataManager.predicate(forKeyPath: "isForApproval", notValue: "1")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateA, predicateB])
        }
        
        let sortDescriptor = NSSortDescriptor(key: "firstName", ascending: self.isAscending)
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
                    self.configureCell(cell as! ARFGAUserTableViewCell, atIndexPath: indexPath)
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
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GAV_USER_DETAILS_VIEW {
            guard let data = sender as? [String: Any], let user = data["user"] as? User else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let userDetailsView = segue.destination as! ARFGAUserDetailsViewController
            userDetailsView.user = user
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GAV_USER_CREATION_VIEW {
            guard let data = sender as? [String: Any], let user = data["user"] as? DeepCopyUser, let isCreation = data["isCreation"] as? Bool else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let userCreationView = segue.destination as! ARFGAUserCreationViewController
            userCreationView.user = user
            userCreationView.isCreation = isCreation
            userCreationView.delegate = self
        }
        
    }
    
    // MARK: - ARFGAUserCreationViewControllerDelegate
    
    func requestUpdateView() {
        DispatchQueue.main.async(execute: {
            self.reloadUserList()
        })
    }

}
