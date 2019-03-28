//
//  ARFGCGameViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 18/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD

class ARFGCGameViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate, ARFGCGameCreationViewControllerDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var dimmedView: UIView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!
    
    var loggedUserId: Int64 = 0
    
    fileprivate var tableRefreshControl: UIRefreshControl!
    fileprivate var searchKey = ""
    fileprivate var isAscending = true
    fileprivate var gameCount = 1
    
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
        
        /// Configure pull to refresh
        let action = #selector(self.refreshGameList)
        self.tableRefreshControl = UIRefreshControl()
        self.tableRefreshControl.addTarget(self, action: action, for: .valueChanged)
        self.tableView.addSubview(self.tableRefreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Customize navigation
        self.customizeNavigationBar()
        
        /// Request for list of games
        self.reloadGameList()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    /// Renders retrieved list of games from database on the
    /// table view as the view has loaded.
    @objc fileprivate func reloadGameList() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.arfDataManager.requestRetrieveGames(forUserWithId: "\(self.loggedUserId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let count = result!["count"] as! Int
                    self.gameCount = count
                    self.title = "Lessons (\(count))"
                    
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
    
    /// Renders retrieved list of games from database on the
    /// table view as user pulls the table view.
    @objc fileprivate func refreshGameList() {
        self.arfDataManager.requestRetrieveGames(forUserWithId: "\(self.loggedUserId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let count = result!["count"] as! Int
                    self.gameCount = count
                    self.title = "Lessons (\(count))"
                    
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
        self.navigationController?.navigationBar.barTintColor = ARFConstants.color.GCV_NAV_GAM_MOD
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        
        /// Configure add button
        let addButton = UIButton(type: UIButtonType.custom)
        addButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        addButton.showsTouchWhenHighlighted = true
        addButton.setImage(ARFConstants.image.GCV_ADD_GAME, for: UIControlState())
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
        self.searchBar.placeholder = "Search Lesson"
        self.searchBar.delegate = self
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func customBackButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /// Presents game details view if deep copying of
    /// game object succeeded where user can create a
    /// new game.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func addButtonAction(_ sender: UIButton) {
        self.arfDataManager.deepCopyGameObject(nil, owner: self.loggedUserId, isCreation: true) { (result) in
            if result != nil {
                DispatchQueue.main.async {
                    let game = result!["game"] as! DeepCopyGame
                    let data: [String: Any] = ["gameId": game.id, "isCreation": true]
                    self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_GAME_CREATION_VIEW, sender: data)
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
    /// requests for game list or search for specific
    /// games.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        var shouldShow = show
        if (self.searchBar.text == "") { shouldShow = self.gameCount > 0 ? false : true }
        
        if (shouldShow) {
            var message = "No available lesson yet."
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
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.GAME, for: indexPath) as! ARFGCGameTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ARFGCGameTableViewCell, atIndexPath indexPath: IndexPath) {
        let gameObject = fetchedResultsController.object(at: indexPath) as! Game
        cell.gameNameLabel.text = gameObject.name!
        cell.gameDiscussionLabel.text = gameObject.discussion!
        cell.gameActPointsLabel.text = "\(gameObject.totalPoints)"
        cell.gamePointsLabel.text = gameObject.totalPoints > 1 ? "Points" : "Point"
        cell.gameImage.image = ARFConstants.image.GCV_GAME
        cell.gameSecurityStatusImage.image = gameObject.isSecure == 1 ? ARFConstants.image.GCV_GAME_LOCKED :  ARFConstants.image.GCV_GAME_UNLOCKED
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let gameObject = fetchedResultsController.object(at: indexPath) as! Game
        let data: [String: Any] = ["game": gameObject]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_GAME_DETAILS_VIEW, sender: data)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let gameObject = fetchedResultsController.object(at: indexPath) as! Game
        
        let deployAction = UIContextualAction(style: .normal, title: "", handler: { (action: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            self.arfDataManager.requestRetrieveClasses(forGameWithId: "\(gameObject.id)", completion: { (result) in
                if result != nil {
                    DispatchQueue.main.async {
                        let classIds = result!["classIds"] as! [Int64]
                        let data: [String: Any] = ["gameId": gameObject.id, "gameName": gameObject.name ?? "", "classIds": classIds]
                        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_GAME_CLASS_SELECTION_VIEW, sender: data)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        let subtitle = "Sorry, but there was an error processing your request. Please try again later."
                        HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                    }
                }
            })
            
            success(true)
        })
        
        let resultAction = UIContextualAction(style: .normal, title: "", handler: { (action: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            success(true)
            DispatchQueue.main.async {
                let data: [String: Any] = ["gameId": gameObject.id, "gameName": gameObject.name!]
                self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_GAME_RESULT_VIEW, sender: data)
            }
        })

        let updateAction = UIContextualAction(style: .normal, title: "", handler: { (action: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            self.arfDataManager.deepCopyGameObject(gameObject, owner: self.loggedUserId, isCreation: false, completion: { (result) in
                if result != nil {
                    DispatchQueue.main.async {
                        let game = result!["game"] as! DeepCopyGame
                        let data: [String: Any] = ["gameId": game.id, "isCreation": false]
                        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_GAME_CREATION_VIEW, sender: data)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        let subtitle = "Sorry, but there was an error processing your request. Please try again later."
                        HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                    }
                }
            })

            success(true)
        })

        let deleteAction = UIContextualAction(style: .normal, title: "", handler: { (action: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            let message = "Are you sure you want to delete \"\(gameObject.name!)\"?"
            let alert = UIAlertController(title: "Delete Lesson", message: message, preferredStyle: .alert)

            let posAction = UIAlertAction(title: "Yes", style: .default) { (Alert) -> Void in
                HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
                
                self.arfDataManager.requestDeleteGame(withId: "\(gameObject.id)", completion: { (result) in
                    let status = result!["status"] as! Int

                    if status == 0 {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = result!["message"] as! String
                            HUD.flash(.labeledSuccess(title: "Delete Lesson", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                                self.reloadGameList()
                                alert.dismiss(animated: true, completion: nil)
                            })
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = result!["message"] as! String
                            HUD.flash(.labeledError(title: "Delete Lesson", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
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

        deployAction.image = ARFConstants.image.GCV_GAME_DEPLOY
        deployAction.backgroundColor = .green
        
        resultAction.image = ARFConstants.image.GCV_GAME_VIEW_RESULTS
        resultAction.backgroundColor = .yellow
        
        updateAction.image = ARFConstants.image.GEN_UPDATE_MAROON
        updateAction.backgroundColor = .orange

        deleteAction.image = ARFConstants.image.GEN_DELETE
        deleteAction.backgroundColor = .red

        return UISwipeActionsConfiguration(actions: [deleteAction, updateAction, resultAction, deployAction])
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.GAME)
        fetchRequest.fetchBatchSize = 20
        
        if (self.searchKey != "") {
            let predicate = self.arfDataManager.predicate(forKeyPath: "searchString", containsValue: self.searchKey)
            fetchRequest.predicate = predicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "dateUpdated", ascending: self.isAscending)
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
                    self.configureCell(cell as! ARFGCGameTableViewCell, atIndexPath: indexPath)
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
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_GAME_DETAILS_VIEW {
            guard let data = sender as? [String: Any], let game = data["game"] as? Game else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameDetailsView = segue.destination as! ARFGCGameDetailsViewController
            gameDetailsView.game = game
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_GAME_CREATION_VIEW {
            guard let data = sender as? [String: Any], let gameId = data["gameId"] as? Int64, let isCreation = data["isCreation"] as? Bool else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameCreationView = segue.destination as! ARFGCGameCreationViewController
            gameCreationView.gameId = gameId
            gameCreationView.isCreation = isCreation
            gameCreationView.delegate = self
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_GAME_CLASS_SELECTION_VIEW {
            guard let data = sender as? [String: Any], let gameId = data["gameId"] as? Int64, let gameName = data["gameName"] as? String, let classIds = data["classIds"] as? [Int64] else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameClassSelectionView = segue.destination as! ARFGCGameClassSelectionViewController
            gameClassSelectionView.gameId = gameId
            gameClassSelectionView.gameName = gameName
            gameClassSelectionView.selectedClasses = classIds
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_GAME_RESULT_VIEW {
            guard let data = sender as? [String: Any], let gameId = data["gameId"] as? Int64, let gameName = data["gameName"] as? String else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameResultView = segue.destination as! ARFGCGameResultViewController
            gameResultView.gameId = gameId
            gameResultView.gameName = gameName
            gameResultView.isCreator = true
        }
        
    }
    
    // MARK: - ARFGCGameCreationViewControllerDelegate
    
    func requestUpdateView() {
        DispatchQueue.main.async(execute: {
            self.reloadGameList()
        })
    }
    
}
