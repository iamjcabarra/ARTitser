//
//  ARFGPGameViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 07/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import SDWebImage
import PKHUD

class ARFGPGameViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var emptyPlaceholderContentView: UIView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var dimmedView: UIView!
    
    var classId: Int64 = 0
    
    fileprivate var collectionRefreshControl: UIRefreshControl!
    fileprivate var blockOperations: [BlockOperation] = []
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
        self.collectionRefreshControl = UIRefreshControl()
        self.collectionRefreshControl.addTarget(self, action: action, for: .valueChanged)
        self.collectionView.addSubview(self.collectionRefreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Decorate navigation bar
        self.customizeNavigationBar()
        
        /// Request for list of games
        self.arfDataManager.requestRetrieveFinishedGames(forClassWithId: "\(self.classId)", playerId: "\(self.arfDataManager.loggedUserId)") { (result) in
            DispatchQueue.main.async { self.reloadGameList() }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    /// Renders retrieved list of games from database on the
    /// table view as the view has loaded.
    @objc fileprivate func reloadGameList() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.arfDataManager.requestRetrieveGames(forClassWithId: "\(self.classId)") { (result) in
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
        self.arfDataManager.requestRetrieveGames(forClassWithId: "\(self.classId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let count = result!["count"] as! Int
                    self.gameCount = count
                    self.title = "Lessons (\(count))"
                    
                    self.collectionRefreshControl.endRefreshing()
                    self.reloadFetchedResultsController()
                }
            }
            else {
                DispatchQueue.main.async {
                    self.collectionRefreshControl.endRefreshing()
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
        self.navigationController?.navigationBar.barTintColor = ARFConstants.color.GPV_NAV_DASHBOARD
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        
        /// Configure custom back button
        let customBackButton = UIButton(type: UIButtonType.custom)
        customBackButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        customBackButton.showsTouchWhenHighlighted = true
        customBackButton.setImage(ARFConstants.image.GEN_CHEVRON, for: UIControlState())
        let customBackButtonAction = #selector(self.customBackButtonAction(_:))
        customBackButton.addTarget(self, action: customBackButtonAction, for: .touchUpInside)
        
        /// Add button to the left navigation bar
        let customBackButtonItem = UIBarButtonItem(customView: customBackButton)
        self.navigationItem.leftBarButtonItem = customBackButtonItem
        
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
    /// requests for game list.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        var shouldShow = show
        if (self.searchBar.text == "") { shouldShow = self.gameCount > 0 ? false : true }
        
        if (shouldShow) {
            var message = "No lesson is deployed in this class yet."
            if (self.searchBar.text != "") { message = "No results found for \"\(self.searchKey)\"." }
            self.emptyPlaceholderLabel.text = message
        }
        
        self.emptyPlaceholderView.isHidden = !shouldShow
        self.collectionView.isHidden = show
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
    
    // MARK: - Collection View Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sectionCount = fetchedResultsController.sections?.count else { return 0 }
        return sectionCount
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sectionData = fetchedResultsController.sections?[section] else { return 0 }
        self.shouldShowEmptyPlaceholderView((sectionData.numberOfObjects > 0) ? false : true)
        return sectionData.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = ARFConstants.cellIdentifier.GAME
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ARFGPGameCollectionViewCell
        let gameObject = fetchedResultsController.object(at: indexPath) as! Game
        
        cell.gameNameLabel.text = gameObject.name!
        cell.gameImage.image = ARFConstants.image.GPV_TREASURE
        cell.backView.layer.borderColor = UIColor.darkGray.cgColor
        cell.backView.layer.borderWidth = 2
    
        let entity = ARFConstants.entity.FINISHED_GAME
        let predicate = self.arfDataManager.predicate(forKeyPath: "gameId", exactValue: "\(gameObject.id)")
        if let finishedGame = self.arfDataManager.db.retrieveObject(forEntity: entity , filteredBy: predicate) as? FinishedGame {
            let imageUrl = finishedGame.imageUrl!
            cell.gameImage.sd_setImage(with: URL(string: imageUrl), completed: { (image, error, type, url) in
                cell.gameImage.image = image != nil ? image! : ARFConstants.image.GPV_TREASURE
            })
        }
        
        return cell
    }
    
    // MARK: - Collection View Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gameObject = self.fetchedResultsController.object(at: indexPath) as! Game
        let entity = ARFConstants.entity.FINISHED_GAME
        let predicate = self.arfDataManager.predicate(forKeyPath: "gameId", exactValue: "\(gameObject.id)")
        
        if let finishedGame = self.arfDataManager.db.retrieveObject(forEntity: entity, filteredBy: predicate) as? FinishedGame {
            DispatchQueue.main.async {
                let data: [String: Any] = ["gameId": finishedGame.gameId, "gameName": gameObject.name!]
                self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_GAME_RESULT_VIEW, sender: data)
            }
        }
        else {
            HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
            
//            self.arfDataManager.requestRetrieveSidekick(forPlayerWithId: "\(self.arfDataManager.loggedUserId)") { (result) in
//                let status = result!["status"] as! Int
//                let count = result!["count"] as! Int
//
//                if status == 0 {
//                    if count > 0 {
//                        DispatchQueue.main.async { HUD.hide() }
//                        let isNoExpiration = gameObject.isNoExpiration == 1 ? true : false
//
//                        if !isNoExpiration {
//                            let minutes: Double = gameObject.isTimeBound == 1 ? Double(gameObject.minutes) * 60.0 : 0.0
//                            let frDate = Date()
//                            let toDate = gameObject.end ?? Date()
//                            let aDifference = toDate.timeIntervalSince(frDate)
//
//                            if aDifference <= minutes {
//                                DispatchQueue.main.async {
//                                    let message = "You can no longer play \"\(gameObject.name!)\" as it has already been expired."
//                                    HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in })
//                                }
//
//                                return
//                            }
//
//                            let toStartDate = gameObject.start ?? Date()
//                            let bDifference = toStartDate.timeIntervalSince(frDate)
//
//                            if bDifference > 0 {
//                                DispatchQueue.main.async {
//                                    let dateString = self.arfDataManager.string(fromDate: toStartDate, format: ARFConstants.timeFormat.CLIENT_LONG_DATE_TIME)
//                                    let message = "\"\(gameObject.name!)\" will be available on \(dateString)."
//                                    HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in })
//                                }
//
//                                return
//                            }
//                        }
//
//                        DispatchQueue.main.async {
//                            let isSecure = gameObject.isSecure == 1 ? true : false
//
//                            if isSecure {
//                                let title = gameObject.name!
//                                let message = "Enter Security Code"
//                                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//
//                                alert.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
//                                    textField.placeholder = ""
//                                    textField.isSecureTextEntry = false
//                                })
//
//                                let posAction = UIAlertAction(title: "Continue", style: .default, handler: {(_ action: UIAlertAction) -> Void in
//                                    let securityCode = alert.textFields?[0].text ?? ""
//                                    let encryptedSecurityCode = securityCode.md5()
//
//                                    if encryptedSecurityCode == gameObject.encryptedSecurityCode! {
//                                        let data: [String: Any] = ["game": gameObject]
//                                        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_GAME_DISCUSSION_VIEW, sender: data)
//                                    }
//                                    else {
//                                        let message = "The security code that you have entered is incorrect."
//                                        HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in })
//                                    }
//                                })
//
//                                let negAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
//                                    DispatchQueue.main.async(execute: { alert.dismiss(animated: true, completion: nil) })
//                                })
//
//                                alert.addAction(posAction)
//                                alert.addAction(negAction)
//                                self.present(alert, animated: true, completion: nil)
//                            }
//                            else {
//                                let data: [String: Any] = ["game": gameObject]
//                                self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_GAME_DISCUSSION_VIEW, sender: data)
//                            }
//                        }
//                    }
//                    else {
//                        DispatchQueue.main.async {
//                            HUD.hide()
//                            let message = "You can't play any game from the list as you haven't selected a sidekick yet."
//                            HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in })
//                        }
//                    }
//                }
//                else {
//                    DispatchQueue.main.async {
//                        HUD.hide()
//                        let subtitle = result!["message"] as! String
//                        HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
//                    }
//                }
            
            DispatchQueue.main.async { HUD.hide() }
            let isNoExpiration = gameObject.isNoExpiration == 1 ? true : false
            
            if !isNoExpiration {
                let minutes: Double = gameObject.isTimeBound == 1 ? Double(gameObject.minutes) * 60.0 : 0.0
                let frDate = Date()
                let toDate = gameObject.end ?? Date()
                let aDifference = toDate.timeIntervalSince(frDate)
                
                if aDifference <= minutes {
                    DispatchQueue.main.async {
                        let message = "You can no longer access \"\(gameObject.name!)\" as it has already been expired."
                        HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in })
                    }
                    
                    return
                }
                
                let toStartDate = gameObject.start ?? Date()
                let bDifference = toStartDate.timeIntervalSince(frDate)
                
                if bDifference > 0 {
                    DispatchQueue.main.async {
                        let dateString = self.arfDataManager.string(fromDate: toStartDate, format: ARFConstants.timeFormat.CLIENT_LONG_DATE_TIME)
                        let message = "\"\(gameObject.name!)\" will be available on \(dateString)."
                        HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in })
                    }
                    
                    return
                }
            }
            
            DispatchQueue.main.async {
                let isSecure = gameObject.isSecure == 1 ? true : false
                
                if isSecure {
                    let title = gameObject.name!
                    let message = "Enter Access Code"
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    
                    alert.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
                        textField.placeholder = ""
                        textField.isSecureTextEntry = false
                    })
                    
                    let posAction = UIAlertAction(title: "Continue", style: .default, handler: {(_ action: UIAlertAction) -> Void in
                        let securityCode = alert.textFields?[0].text ?? ""
                        let encryptedSecurityCode = securityCode.md5()
                        
                        if encryptedSecurityCode == gameObject.encryptedSecurityCode! {
                            let data: [String: Any] = ["game": gameObject]
                            self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_GAME_DISCUSSION_VIEW, sender: data)
                        }
                        else {
                            let message = "The access code that you have entered is incorrect."
                            HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in })
                        }
                    })
                    
                    let negAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
                        DispatchQueue.main.async(execute: { alert.dismiss(animated: true, completion: nil) })
                    })
                    
                    alert.addAction(posAction)
                    alert.addAction(negAction)
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    let data: [String: Any] = ["game": gameObject]
                    self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_GAME_DISCUSSION_VIEW, sender: data)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 80
        let width = collectionView.frame.size.width - padding
        return CGSize(width: width / 2, height: 150)
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
        
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: self.isAscending)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: ctx!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch _ as NSError {
            abort()
        }
        
        return _fetchedResultsController!
    }
    
    fileprivate func addProcessingBlock(_ processingBlock:@escaping ()->Void) {
        self.blockOperations.append(BlockOperation(block: processingBlock))
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.blockOperations.removeAll(keepingCapacity: false)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            self.addProcessingBlock { [weak self] in self?.collectionView.insertItems(at: [newIndexPath]) }
            
        case .update:
            guard let newIndexPath = newIndexPath else { return }
            self.addProcessingBlock { [weak self] in self?.collectionView.reloadItems(at: [newIndexPath]) }
            
        case .move:
            guard let indexPath = indexPath else { return }
            guard let newIndexPath = newIndexPath else { return }
            self.addProcessingBlock { [weak self] in self?.collectionView.moveItem(at: indexPath, to: newIndexPath) }
            
        case .delete:
            guard let indexPath = indexPath else { return }
            self.addProcessingBlock { [weak self] in self?.collectionView.deleteItems(at: [indexPath]) }
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            self.addProcessingBlock { [weak self] in self?.collectionView.insertSections(IndexSet(integer: sectionIndex)) }
            
        case .update:
            self.addProcessingBlock { [weak self] in self?.collectionView.reloadSections(IndexSet(integer: sectionIndex)) }
            
        case .delete:
            self.addProcessingBlock { [weak self] in self?.collectionView.deleteSections(IndexSet(integer: sectionIndex)) }
            
        default: break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.collectionView.performBatchUpdates({
            self.blockOperations.forEach { $0.start() }
        }, completion: { finished in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    
    func reloadFetchedResultsController() {
        self._fetchedResultsController = nil
        self.collectionView.reloadData()
        
        var error: NSError? = nil
        
        do {
            try self.fetchedResultsController.performFetch()
        }
        catch let error1 as NSError {
            error = error1
            print(error?.localizedDescription ?? "")
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_GAME_DISCUSSION_VIEW {
            guard let data = sender as? [String: Any], let game = data["game"] as? Game else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameDiscussionView = segue.destination as! ARFGPGameDiscussionViewController
            gameDiscussionView.classId = self.classId
            gameDiscussionView.game = game
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_GAME_RESULT_VIEW {
            guard let data = sender as? [String: Any], let gameId = data["gameId"] as? Int64, let gameName = data["gameName"] as? String else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameResultView = segue.destination as! ARFGCGameResultViewController
            gameResultView.gameId = gameId
            gameResultView.gameName = gameName
            gameResultView.classId = self.classId
            gameResultView.isCreator = false
        }
        
    }
    
}
