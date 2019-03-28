//
//  ARFGADashboardViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 23/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD

class ARFGADashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet var userView: UIView!
    @IBOutlet var courseView: UIView!
    @IBOutlet var classView: UIView!
    @IBOutlet var userCountLabel: UILabel!
    @IBOutlet var courseCountLabel: UILabel!
    @IBOutlet var classCountLabel: UILabel!
    @IBOutlet var userButton: UIButton!
    @IBOutlet var courseButton: UIButton!
    @IBOutlet var classButton: UIButton!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    fileprivate var tableRefreshControl: UIRefreshControl!
    fileprivate var aboutPopover: ARFGENAboutPopover!
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Set navigation title
        self.title = "Dashboard"
        
        /// Configure views
        self.userView.backgroundColor = ARFConstants.color.GAV_NAV_USR_MOD
        self.userView.addShadow(offset: CGSize(width: -1, height: 1), color: .darkGray, radius: 1, opacity: 1)
        self.courseView.backgroundColor = ARFConstants.color.GAV_NAV_CRS_MOD
        self.courseView.addShadow(offset: CGSize(width: -1, height: 1), color: .darkGray, radius: 1, opacity: 1)
        self.classView.backgroundColor = ARFConstants.color.GAV_NAV_CLA_MOD
        self.classView.addShadow(offset: CGSize(width: -1, height: 1), color: .darkGray, radius: 1, opacity: 1)
        
        /// Configure listeners for buttons
        self.userButton.addTarget(self, action: #selector(self.userButtonAction(_:)), for: .touchUpInside)
        self.courseButton.addTarget(self, action: #selector(self.courseButtonAction(_:)), for: .touchUpInside)
        self.classButton.addTarget(self, action: #selector(self.classButtonAction(_:)), for: .touchUpInside)
        
        /// Remove extra padding on the top of the table view
        self.tableView.contentInset = UIEdgeInsetsMake(-35, 0, 0, 0);
        
        /// Configure tableview's border
        self.tableView.layer.masksToBounds = true
        self.tableView.layer.borderColor = UIColor.lightGray.cgColor
        self.tableView.layer.borderWidth = 0.5
        
        /// Configure pull to refresh
        let action = #selector(self.refreshUserList)
        self.tableRefreshControl = UIRefreshControl()
        self.tableRefreshControl.addTarget(self, action: action, for: .valueChanged)
        self.tableView.addSubview(self.tableRefreshControl)
        
        /// Configure empty place holder
        self.emptyPlaceholderView.isHidden = true
        self.emptyPlaceholderLabel.text = "No newly registered user who needs your approval."
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        /// Decorate navigation bar
        self.customizeNavigationBar()
        
        /// Render statistics
        self.reloadStatisticsPrimary()
        
        /// Request for list of users for approval
        self.reloadUserList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Custom Navigation Bar
    
    /// Customizes navigation controller's navigation
    /// bar.
    fileprivate func customizeNavigationBar() {
        /// Configure navigation bar
        self.navigationController?.navigationBar.barTintColor = ARFConstants.color.GAV_NAV_DASHBOARD
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
        
        /// Add button to the left navigation bar
        let userInfoButtonItem = UIBarButtonItem(customView: userInfoButton)
        self.navigationItem.leftBarButtonItem = userInfoButtonItem
        
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
        let aboutButtonItem = UIBarButtonItem(customView: aboutButton)
        let logOutButtonItem = UIBarButtonItem(customView: logOutButton)
        self.navigationItem.rightBarButtonItems = [logOutButtonItem, aboutButtonItem]
    }
    
    // MARK: - Statistics Dashboard Primary
    
    /// Requests number of users, courses and classes stored
    /// in the database and renders them on dashboard.
    fileprivate func reloadStatisticsPrimary() {
        self.arfDataManager.requestRetrieveStatisticsAdministratorDashboardPrimary(forUserWithId: "\(self.arfDataManager.loggedUserId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let statistics = result!["statistics"] as! [String: Int64]
                    self.userCountLabel.text = "\(statistics["users"] ?? 0)"
                    self.courseCountLabel.text = "\(statistics["courses"] ?? 0)"
                    self.classCountLabel.text = "\(statistics["classes"] ?? 0)"
                }
            }
            else {
                DispatchQueue.main.async {
                    self.userCountLabel.text = "0"
                    self.courseCountLabel.text = "0"
                    self.classCountLabel.text = "0"
                }
            }
        }
    }
    
    // MARK: - Reload Registered User List
    
    /// Renders retrieved list of users from database on the
    /// table view as the view has loaded.
    @objc fileprivate func reloadUserList() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.arfDataManager.requestRetrieveUsers() { (result) in
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
    
    /// Renders retrieved list of users from database on the
    /// table view as user pulls the table view.
    @objc fileprivate func refreshUserList() {
        self.arfDataManager.requestRetrieveUsers() { (result) in
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
    
    /// Presents user's view as user clicks on user
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func userButtonAction(_ sender: UIButton) {
        let data = ["loggedUserId": self.arfDataManager.loggedUserId] as [String : Any]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GAV_USER_VIEW, sender: data)
    }
    
    /// Presents course's view as user clicks on course
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func courseButtonAction(_ sender: UIButton) {
        let data = ["loggedUserId": self.arfDataManager.loggedUserId] as [String : Any]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GAV_COURSE_VIEW, sender: data)
    }
    
    /// Presents class view as user clicks on class
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func classButtonAction(_ sender: UIButton) {
        let data = ["loggedUserId": self.arfDataManager.loggedUserId] as [String : Any]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GAV_CLASS_VIEW, sender: data)
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sectionCount = fetchedResultsController.sections?.count else { return 0 }
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionData = fetchedResultsController.sections?[section] else { return 0 }
        self.emptyPlaceholderView.isHidden = (sectionData.numberOfObjects > 0) ? true : false
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
        cell.extraLabel.text = "Registered last \(self.arfDataManager.string(fromDate: dateCreated, format: "MMM. dd, yyyy"))"
        
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

        let approveAction = UIContextualAction(style: .normal, title: "", handler: { (action: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
            
            self.arfDataManager.requestApproveUser(withId: "\(userObject.id)", body: ["isForApproval": "0"], completion: { (result) in
                let status = result!["status"] as! Int
    
                if status == 0 {
                    DispatchQueue.main.async {
                        HUD.hide()
                        let subtitle = result!["message"] as! String
                        HUD.flash(.labeledSuccess(title: "Approve User Registration", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                            self.reloadUserList()
                            self.reloadStatisticsPrimary()
                        })
                    }
                }
                else {
                    DispatchQueue.main.async {
                        HUD.hide()
                        let subtitle = result!["message"] as! String
                        HUD.flash(.labeledError(title: "Approve User Registration", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                    }
                }
            })
            
            success(true)
        })
        
        approveAction.image = ARFConstants.image.GAV_APPROVE
        approveAction.backgroundColor = .green
        
        return UISwipeActionsConfiguration(actions: [approveAction])
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
        
        let predicateA = self.arfDataManager.predicate(forKeyPath: "id", notValue: "\(self.arfDataManager.loggedUserId)")
        let predicateB = self.arfDataManager.predicate(forKeyPath: "isForApproval", exactValue: "1")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateA, predicateB])
        
        let sortDescriptor = NSSortDescriptor(key: "dateCreated", ascending: true)
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
        
        if segue.identifier == ARFConstants.segueIdentifier.GAV_USER_VIEW {
            guard let data = sender as? [String: Any], let loggedUserId = data["loggedUserId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let userView = segue.destination as! ARFGAUserViewController
            userView.loggedUserId = loggedUserId
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GAV_COURSE_VIEW {
            guard let data = sender as? [String: Any], let loggedUserId = data["loggedUserId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let courseView = segue.destination as! ARFGACourseViewController
            courseView.loggedUserId = loggedUserId
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GAV_CLASS_VIEW {
            guard let data = sender as? [String: Any], let loggedUserId = data["loggedUserId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let classView = segue.destination as! ARFGAClassViewController
            classView.loggedUserId = loggedUserId
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GEN_MY_ACCOUNT_VIEW {
            guard let data = sender as? [String: Any], let user = data["user"] as? DeepCopyUser else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let myAccountView = segue.destination as! ARFGENMyAccountViewController
            myAccountView.user = user
            myAccountView.userType = ARFConstants.userType.GA
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GAV_USER_DETAILS_VIEW {
            guard let data = sender as? [String: Any], let user = data["user"] as? User else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let userDetailsView = segue.destination as! ARFGAUserDetailsViewController
            userDetailsView.user = user
            userDetailsView.isReview = true
        }

    }
    
    // MARK: - Popover Presentation Controller Delegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

}
