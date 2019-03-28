//
//  ARFGCDashboardViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 14/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD
import Charts
import ChartsRealm

protocol GetChartData {
    func getChartData(with dataPoins: [String], values: [String], names: [String])
    var percentages: [String] {get set}
    var ratePerGame: [String] {get set}
    var gameNames: [String] {get set}
}

class ARFGCDashboardViewController: UIViewController, UIPopoverPresentationControllerDelegate, GetChartData {
    
    @IBOutlet var clueView: UIView!
    @IBOutlet var treasureView: UIView!
    @IBOutlet var gameView: UIView!
    @IBOutlet var clueCountLabel: UILabel!
    @IBOutlet var treasureCountLabel: UILabel!
    @IBOutlet var gameCountLabel: UILabel!
    @IBOutlet var clueButton: UIButton!
    @IBOutlet var treasureButton: UIButton!
    @IBOutlet var gameButton: UIButton!
    @IBOutlet var chartView: UIView!
    
    var percentages = [String]()
    var ratePerGame = [String]()
    var gameNames = [String]()
    
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
        self.clueView.backgroundColor = ARFConstants.color.GCV_NAV_CLU_MOD
        self.clueView.addShadow(offset: CGSize(width: -1, height: 1), color: .darkGray, radius: 1, opacity: 1)
        self.treasureView.backgroundColor = ARFConstants.color.GCV_NAV_TRE_MOD
        self.treasureView.addShadow(offset: CGSize(width: -1, height: 1), color: .darkGray, radius: 1, opacity: 1)
        self.gameView.backgroundColor = ARFConstants.color.GCV_NAV_GAM_MOD
        self.gameView.addShadow(offset: CGSize(width: -1, height: 1), color: .darkGray, radius: 1, opacity: 1)
        self.chartView.addShadow(offset: CGSize(width: -1, height: 1), color: .darkGray, radius: 1, opacity: 1)
        
        /// Configure listeners for buttons
        self.clueButton.addTarget(self, action: #selector(self.clueButtonAction(_:)), for: .touchUpInside)
        self.treasureButton.addTarget(self, action: #selector(self.treasureButtonAction(_:)), for: .touchUpInside)
        self.gameButton.addTarget(self, action: #selector(self.gameButtonAction(_:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Decorate navigation bar
        self.customizeNavigationBar()
        
        /// Render statistics
        self.reloadStatisticsPrimary()
        
        /// Render bar chart
        if self.percentages.count > 0 { self.percentages.removeAll() }
        if self.ratePerGame.count > 0 { self.ratePerGame.removeAll() }
        if self.gameNames.count > 0 { self.gameNames.removeAll() }
        self.populateChartData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Custom Navigation Bar
    
    /// Customizes navigation controller's navigation
    /// bar.
    fileprivate func customizeNavigationBar() {
        /// Configure navigation bar
        self.navigationController?.navigationBar.barTintColor = ARFConstants.color.GCV_NAV_DASHBOARD
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
    
    /// Requests number of clues, treasures and games stored
    /// in the database and renders them on dashboard.
    fileprivate func reloadStatisticsPrimary() {
        self.arfDataManager.requestRetrieveStatisticsCreatorDashboardPrimary(forUserWithId: "\(self.arfDataManager.loggedUserId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let statistics = result!["statistics"] as! [String: Int64]
                    self.clueCountLabel.text = "\(statistics["clues"] ?? 0)"
                    self.treasureCountLabel.text = "\(statistics["treasures"] ?? 0)"
                    self.gameCountLabel.text = "\(statistics["games"] ?? 0)"
                }
            }
            else {
                DispatchQueue.main.async {
                    self.clueCountLabel.text = "0"
                    self.treasureCountLabel.text = "0"
                    self.gameCountLabel.text = "0"
                }
            }
        }
    }
    
    // MARK: - Dasboard Chart Handler
    
    /// Renders bar chart for success rate of deployed
    /// games.
    fileprivate func populateChartData() {
        self.arfDataManager.requestRetrieveGameSuccessRate(forUserWithId: "\(self.arfDataManager.loggedUserId)") { (result) in
            let status = result!["status"] as! Int

            if status == 0 {
                self.percentages = ["0", "10", "20", "30", "40", "50", "60", "70", "80", "90", "100"]
                let gpos = result!["gpos"] as! [[String: Any]]
                
                for gpo in gpos {
                    let rate = gpo["gpos"] as! Double
                    let gameName = gpo["gameName"] as! String
                    self.ratePerGame.append("\(rate)")
                    self.gameNames.append(gameName)
                }
                
                self.getChartData(with: self.percentages, values: self.ratePerGame, names: self.gameNames)
                DispatchQueue.main.async { self.loadBarChart() }
            }
        }
    }
    
    /// Creates bar chart.
    fileprivate func loadBarChart() {
        let frame = CGRect(x: 0, y: 0, width: self.chartView.bounds.width, height: self.chartView.bounds.height)
        let barChart = ARFBarChart(frame: frame)
        barChart.delegate = self
        self.chartView.addSubview(barChart)
    }
    
    /// Implements protocol for chart data.
    func getChartData(with dataPoins: [String], values: [String], names: [String]) {
        self.percentages = dataPoins
        self.ratePerGame = values
        self.gameNames = names
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
    
    /// Presents clue's view as user clicks on user
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func clueButtonAction(_ sender: UIButton) {
        let data = ["loggedUserId": self.arfDataManager.loggedUserId] as [String : Any]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_CLUE_VIEW, sender: data)
    }
    
    /// Presents treasure's view as user clicks on course
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func treasureButtonAction(_ sender: UIButton) {
        let data = ["loggedUserId": self.arfDataManager.loggedUserId] as [String : Any]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_TREASURE_VIEW, sender: data)
    }
    
    /// Presents game's view as user clicks on class
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func gameButtonAction(_ sender: UIButton) {
        let data = ["loggedUserId": self.arfDataManager.loggedUserId] as [String : Any]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_GAME_VIEW, sender: data)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_CLUE_VIEW {
            guard let data = sender as? [String: Any], let loggedUserId = data["loggedUserId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let clueView = segue.destination as! ARFGCClueViewController
            clueView.loggedUserId = loggedUserId
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_TREASURE_VIEW {
            guard let data = sender as? [String: Any], let loggedUserId = data["loggedUserId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let treasureView = segue.destination as! ARFGCTreasureViewController
            treasureView.loggedUserId = loggedUserId
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_GAME_VIEW {
            guard let data = sender as? [String: Any], let loggedUserId = data["loggedUserId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameView = segue.destination as! ARFGCGameViewController
            gameView.loggedUserId = loggedUserId
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GEN_MY_ACCOUNT_VIEW {
            guard let data = sender as? [String: Any], let user = data["user"] as? DeepCopyUser else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let myAccountView = segue.destination as! ARFGENMyAccountViewController
            myAccountView.user = user
            myAccountView.userType = ARFConstants.userType.GC
        }
        
    }
    
    // MARK: - Popover Presentation Controller Delegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

}
