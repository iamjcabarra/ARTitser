//
//  ARFGPClassViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 06/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD

class ARFGPClassViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!
    @IBOutlet var backgroundImage: UIImageView!
    
    fileprivate var loggedUserId: Int64 = 0
    fileprivate var collectionRefreshControl: UIRefreshControl!
    fileprivate var blockOperations: [BlockOperation] = []
    fileprivate var aboutPopover: ARFGENAboutPopover!
    fileprivate var classCount = 1
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Set user id
        self.loggedUserId = self.arfDataManager.loggedUserId
        
        /// Retrieve sidekick
        self.retrieveSidekick(forFirstLoad: true)
        
        /// Empty navigation bar title by default
        self.title = ""
        
        /// Hide empty place holder by default
        self.shouldShowEmptyPlaceholderView(false)
        
        /// Configure pull to refresh
        let action = #selector(self.refreshClassList)
        self.collectionRefreshControl = UIRefreshControl()
        self.collectionRefreshControl.addTarget(self, action: action, for: .valueChanged)
        self.collectionView.addSubview(self.collectionRefreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Decorate navigation bar
        self.customizeNavigationBar()
        
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
        
        self.arfDataManager.requestRetrieveClasses(forPlayerWithId: "\(self.loggedUserId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let count = result!["count"] as! Int
                    self.classCount = count
                    self.title = "Classes (\(count))"
                    
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
        self.arfDataManager.requestRetrieveClasses(forPlayerWithId: "\(self.loggedUserId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let count = result!["count"] as! Int
                    self.classCount = count
                    self.title = "Classes (\(count))"
                    
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
    
    /// Request retrieval of sidekick. If sidekick exists, it
    /// then goes to the class list view; otherwise, it will
    /// presents sidekick creation view.
    fileprivate func retrieveSidekick(forFirstLoad firstLoad: Bool) {
//        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
//        let playerId = self.arfDataManager.loggedUserId
//
//        self.arfDataManager.requestRetrieveSidekick(forPlayerWithId: "\(playerId)") { (result) in
//            let status = result!["status"] as! Int
//            let count = result!["count"] as! Int
//
//            if status == 0 {
//                if count > 0 {
//                    DispatchQueue.main.async {
//                        HUD.hide()
//
//                        if !firstLoad {
//                            let entity = ARFConstants.entity.SIDEKICK
//                            let predicate = self.arfDataManager.predicate(forKeyPath: "ownedBy", exactValue: "\(playerId)")
//
//                            if let sidekick = self.arfDataManager.db.retrieveObject(forEntity: entity, filteredBy: predicate) as? Sidekick {
//                                let identifier = ARFConstants.segueIdentifier.GPV_SIDEKICK_DETAILS_VIEW
//                                let data: [String: Any] = ["sidekick": sidekick]
//                                self.performSegue(withIdentifier: identifier, sender: data)
//                            }
//                        }
//                    }
//                }
//                else {
//                    self.arfDataManager.deepCopySidekickObject(nil, owner: playerId, isCreation: true, completion: { (result) in
//                        if result != nil {
//                            DispatchQueue.main.async {
//                                HUD.hide()
//                                let sidekick = result!["sidekick"] as! DeepCopySidekick
//                                let data: [String: Any] = ["sidekick": sidekick]
//                                self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_SIDEKICK_SELECTION_VIEW, sender: data)
//                            }
//                        }
//                        else {
//                            DispatchQueue.main.async {
//                                HUD.hide()
//                                let subtitle = ARFConstants.message.DEFAULT_ERROR
//                                HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
//                                    self.dismiss(animated: true, completion: nil)
//                                })
//                            }
//                        }
//                    })
//                }
//            }
//            else {
//                DispatchQueue.main.async {
//                    HUD.hide()
//                    let subtitle = result!["message"] as! String
//                    HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
//                        self.dismiss(animated: true, completion: nil)
//                    })
//                }
//            }
//        }
        
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        let playerId = self.arfDataManager.loggedUserId
        
        self.arfDataManager.requestRetrieveSidekick(forPlayerWithId: "\(playerId)") { (result) in
            let status = result!["status"] as! Int
            let count = result!["count"] as! Int
            
            if status == 0 && count <= 0 {
                self.arfDataManager.deepCopySidekickObject(nil, owner: playerId, isCreation: true, name: self.arfDataManager.loggedUserFullName ,completion: { (result) in
                    if result != nil {
                        let entity = ARFConstants.entity.DEEP_COPY_SIDEKICK
                        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "0")
                        let rfKeys = ["type", "name", "level", "points", "ownedBy"]
                        let body = self.arfDataManager.assemblePostData(fromEntity: entity, filteredBy: predicate, requiredKeys: rfKeys)
                        
                        if body != nil {
                            self.arfDataManager.requestCreateSidekick(withBody: body!, completion: { (result) in
                                DispatchQueue.main.async { HUD.hide() }
                            })
                        }
                        else {
                            DispatchQueue.main.async { HUD.hide() }
                        }
                    }
                    else {
                        DispatchQueue.main.async { HUD.hide() }
                    }
                })
            }
            else {
                DispatchQueue.main.async { HUD.hide() }
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
        
        /// Configure user button
        let userInfoButton = UIButton(type: UIButtonType.custom)
        userInfoButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        userInfoButton.showsTouchWhenHighlighted = true
        userInfoButton.setImage(ARFConstants.image.GEN_USER_INFO, for: UIControlState())
        let userInfoButtonAction = #selector(self.userInfoButtonAction(_:))
        userInfoButton.addTarget(self, action: userInfoButtonAction, for: .touchUpInside)
        
        /// Configure sidekick button
//        let sidekickButton = UIButton(type: UIButtonType.custom)
//        sidekickButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
//        sidekickButton.showsTouchWhenHighlighted = true
//        sidekickButton.setImage(ARFConstants.image.GPV_NAV_SIDEKICK, for: UIControlState())
//        let sidekickButtonAction = #selector(self.sidekickButtonAction(_:))
//        sidekickButton.addTarget(self, action: sidekickButtonAction, for: .touchUpInside)
        
        /// Configure treasure button
//        let treasureButton = UIButton(type: UIButtonType.custom)
//        treasureButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
//        treasureButton.showsTouchWhenHighlighted = true
//        treasureButton.setImage(ARFConstants.image.GPV_NAV_TREASURE, for: UIControlState())
//        let treasureButtonAction = #selector(self.treasureButtonAction(_:))
//        treasureButton.addTarget(self, action: treasureButtonAction, for: .touchUpInside)
        
        /// Configure ranking button
        let rankingButton = UIButton(type: UIButtonType.custom)
        rankingButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        rankingButton.showsTouchWhenHighlighted = true
        rankingButton.setImage(ARFConstants.image.GPV_NAV_RANKING, for: UIControlState())
        let rankingButtonAction = #selector(self.rankingButtonAction(_:))
        rankingButton.addTarget(self, action: rankingButtonAction, for: .touchUpInside)
        
        /// Add buttons to the left navigation bar
        let userInfoButtonItem = UIBarButtonItem(customView: userInfoButton)
//        let sidekickButtonItem = UIBarButtonItem(customView: sidekickButton)
//        let treasureButtonItem = UIBarButtonItem(customView: treasureButton)
        let rankingButtonItem = UIBarButtonItem(customView: rankingButton)
        self.navigationItem.leftBarButtonItems = [userInfoButtonItem, rankingButtonItem]//[userInfoButtonItem, sidekickButtonItem, treasureButtonItem]
        
//        /// Configure ranking button
//        let rankingButton = UIButton(type: UIButtonType.custom)
//        rankingButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
//        rankingButton.showsTouchWhenHighlighted = true
//        rankingButton.setImage(ARFConstants.image.GPV_NAV_RANKING, for: UIControlState())
//        let rankingButtonAction = #selector(self.rankingButtonAction(_:))
//        rankingButton.addTarget(self, action: rankingButtonAction, for: .touchUpInside)
        
        /// Configure about button
        let aboutButton = UIButton(type: UIButtonType.custom)
        aboutButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        aboutButton.showsTouchWhenHighlighted = true
        aboutButton.setImage(ARFConstants.image.GEN_ABOUT, for: UIControlState())
        let aboutButtonAction = #selector(self.aboutButtonAction(_:))
        aboutButton.addTarget(self, action: aboutButtonAction, for: .touchUpInside)
        
        /// Configure log out button
        let logOutButton = UIButton(type: UIButtonType.custom)
        logOutButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        logOutButton.showsTouchWhenHighlighted = true
        logOutButton.setImage(ARFConstants.image.GEN_LOGOUT, for: UIControlState())
        let logOutButtonAction = #selector(self.logOutButtonAction(_:))
        logOutButton.addTarget(self, action: logOutButtonAction, for: .touchUpInside)
        
        /// Add buttons to the right navigation bar
//        let rankingButtonItem = UIBarButtonItem(customView: rankingButton)
        let aboutButtonItem = UIBarButtonItem(customView: aboutButton)
        let logOutButtonItem = UIBarButtonItem(customView: logOutButton)
        self.navigationItem.rightBarButtonItems = [logOutButtonItem, aboutButtonItem]//[logOutButtonItem, aboutButtonItem, rankingButtonItem]
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to log in view as user confirms logging
    /// off of his account.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func logOutButtonAction(_ sender: UIButton) {
        let message = "Are you sure you want to leave the application?"
        let alert = UIAlertController(title: "Log Out", message: message, preferredStyle: .alert)
        
        let posAction = UIAlertAction(title: "Leave", style: .default) { (Alert) -> Void in
            self.arfDataManager.requestLogoutUser(withId: "\(self.arfDataManager.loggedUserId)", completion: { (result) in
                DispatchQueue.main.async(execute: {
                    let image = ARFConstants.image.GEN_GOODBYE
                    let subtitle = "I hope to see you soon, \(self.arfDataManager.loggedUserFirstName)!"
                    HUD.flash(.labeledImage(image: image, title: "Goodbye!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                        self.dismiss(animated: true, completion: nil)
                    })
                })
            })
        }
        
        let negAction = UIAlertAction(title: "Cancel", style: .cancel) { (Alert) -> Void in
            DispatchQueue.main.async(execute: { alert.dismiss(animated: true, completion: nil) })
        }
        
        alert.addAction(posAction)
        alert.addAction(negAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Fetches user's object from core data and deeps copy
    /// it. If this process succeeds, it presents my account
    /// view where user can view and update his account
    /// details.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func userInfoButtonAction(_ sender: UIButton) {
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.arfDataManager.loggedUserId)")
        guard let userObject = self.arfDataManager.db.retrieveObject(forEntity: ARFConstants.entity.USER, filteredBy: predicate) as? User else {
            print("ERROR: Can't retrieve user object from core data!")
            return
        }
        
        self.arfDataManager.deepCopyUserObject(userObject, owner: self.arfDataManager.loggedUserId, isCreation: false) { (result) in
            if result != nil {
                DispatchQueue.main.async {
                    let data = ["user": result!["user"] as! DeepCopyUser]
                    self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GEN_MY_ACCOUNT_VIEW, sender: data)
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
    
//    /// Presents sidekick details view as user clicks
//    /// sidekick button.
//    ///
//    /// - parameter sender: A UIButton
//    @objc fileprivate func sidekickButtonAction(_ sender: UIButton) {
//        self.retrieveSidekick(forFirstLoad: false)
//    }
    
//    /// Presents treasure view as user clicks on
//    /// treasure button.
//    ///
//    /// - parameter sender: A UIButton
//    @objc fileprivate func treasureButtonAction(_ sender: UIButton) {
//        let data: [String: Any] = ["playerId": self.arfDataManager.loggedUserId]
//        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_TRESURE_VIEW, sender: data)
//    }
    
    /// Presents about view as user clicks on about
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func aboutButtonAction(_ sender: UIButton) {
        self.aboutPopover = ARFGENAboutPopover(nibName: "ARFGENAboutPopover", bundle: nil)
        self.aboutPopover.modalPresentationStyle = .popover
        self.aboutPopover.preferredContentSize = CGSize(width: 250.0, height: 192.0)
        self.aboutPopover.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        self.aboutPopover.popoverPresentationController?.sourceView = self.view
        self.aboutPopover.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        self.aboutPopover.popoverPresentationController?.delegate = self
        self.present(self.aboutPopover, animated: true, completion: nil)
    }
    
    /// Presents ranking view as user clicks on ranking
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func rankingButtonAction(_ sender: UIButton) {
        let data: [String: Any] = ["playerId": self.arfDataManager.loggedUserId]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_RANKING_VIEW, sender: data)
    }
    
    // MARK: - Empty Placeholder View
    
    /// Shows or hides empty place holder view as user
    /// requests for class list.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        self.emptyPlaceholderView.isHidden = !show
        self.collectionView.isHidden = show
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
        let cellIdentifier = ARFConstants.cellIdentifier.CLASS
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ARFGPClassCollectionViewCell
        let classObject = fetchedResultsController.object(at: indexPath) as! Class
        
        cell.classCodeLabel.text = classObject.code!
        cell.classImage.image = ARFConstants.image.GPV_CLASS
        cell.backView.layer.borderColor = UIColor.darkGray.cgColor
        cell.backView.layer.borderWidth = 2
        
        return cell
    }
    
    // MARK: - Collection View Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let classObject = fetchedResultsController.object(at: indexPath) as! Class
        let data: [String: Any] = ["class": classObject]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_CLASS_DETAILS_VIEW, sender: data)
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
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.CLASS)
        fetchRequest.fetchBatchSize = 20
        
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
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
        
        if segue.identifier == ARFConstants.segueIdentifier.GEN_MY_ACCOUNT_VIEW {
            guard let data = sender as? [String: Any], let user = data["user"] as? DeepCopyUser else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let myAccountView = segue.destination as! ARFGENMyAccountViewController
            myAccountView.user = user
            myAccountView.userType = ARFConstants.userType.GP
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_SIDEKICK_SELECTION_VIEW {
            guard let data = sender as? [String: Any], let sidekick = data["sidekick"] as? DeepCopySidekick else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let sidekickSelectionView = segue.destination as! ARFGPSidekickSelectionViewController
            sidekickSelectionView.sidekickId = sidekick.id
            sidekickSelectionView.selectedSidekickType = sidekick.type
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_SIDEKICK_DETAILS_VIEW {
            guard let data = sender as? [String: Any], let sidekick = data["sidekick"] as? Sidekick else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let sidekickDetailsView = segue.destination as! ARFGPSidekickDetailsViewController
            sidekickDetailsView.sidekick = sidekick
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_CLASS_DETAILS_VIEW {
            guard let data = sender as? [String: Any], let klase = data["class"] as? Class else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let classDetailsView = segue.destination as! ARFGPClassDetailsViewController
            classDetailsView.klase = klase
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_TRESURE_VIEW {
            guard let data = sender as? [String: Any], let playerId = data["playerId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let treasureView = segue.destination as! ARFGPTreasureViewController
            treasureView.playerId = playerId
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_RANKING_VIEW {
            guard let data = sender as? [String: Any], let playerId = data["playerId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let rankingView = segue.destination as! ARFGPRankingViewController
            rankingView.playerId = playerId
        }
        
    }
    
    // MARK: - Popover Presentation Controller Delegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

}
