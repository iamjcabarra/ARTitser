//
//  ARFGCGameDetailsViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 04/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGCGameDetailsViewController: UIViewController {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var actNameLabel: UILabel!
    @IBOutlet var discussionLabel: UILabel!
    @IBOutlet var actDiscussionLabel: UILabel!
    @IBOutlet var treasureLabel: UILabel!
    @IBOutlet var actTreasureLabel: UILabel!
    @IBOutlet var cluesLabel: UILabel!
    @IBOutlet var actCluesLabel: UILabel!
    @IBOutlet var totalPointsLabel: UILabel!
    @IBOutlet var actTotalPointsLabel: UILabel!
    @IBOutlet var timeLimitLabel: UILabel!
    @IBOutlet var actTimeLimitLabel: UILabel!
    @IBOutlet var scheduleLabel: UILabel!
    @IBOutlet var actScheduleLabel: UILabel!
    @IBOutlet var securityCodeLabel: UILabel!
    @IBOutlet var actSecurityCodeLabel: UILabel!
    @IBOutlet var dateCreatedLabel: UILabel!
    @IBOutlet var actDateCreatedLabel: UILabel!
    @IBOutlet var dateUpdatedLabel: UILabel!
    @IBOutlet var actDateUpdatedLabel: UILabel!

    var game: Game!
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Render clue details
        self.renderData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Customize navigation
        self.customizeNavigationBar()
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
        self.title = "Lesson Details"
        
        /// Configure custom back button
        let customBackButton = UIButton(type: UIButtonType.custom)
        customBackButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        customBackButton.showsTouchWhenHighlighted = true
        customBackButton.setImage(ARFConstants.image.GEN_CHEVRON, for: UIControlState())
        let customBackButtonAction = #selector(self.customBackButtonAction(_:))
        customBackButton.addTarget(self, action: customBackButtonAction, for: .touchUpInside)
        
        /// Add buttons to the left navigation bar
        let customBackButtonItem = UIBarButtonItem(customView: customBackButton)
        self.navigationItem.leftBarButtonItem = customBackButtonItem
    }
    
    // MARK: - Data Rendering
    
    /// Binds data with controller's view ui objects.
    fileprivate func renderData() {
        if self.game != nil {
            self.actNameLabel.text = self.game.name ?? ""
            self.actDiscussionLabel.text = self.game.discussion ?? ""
            self.actTreasureLabel.text = self.game.treasure != nil ? self.game.treasure!.name ?? "" : ""
            self.actTotalPointsLabel.text = "\(self.game.totalPoints)"
            self.actSecurityCodeLabel.text = self.game.securityCode ?? ""
            
            let isTimeBoundString = "\(self.game.minutes) \(self.game.minutes > 1 ? "minutes" : "minute")"
            self.actTimeLimitLabel.text = self.game.isTimeBound == 1 ? isTimeBoundString : "Not time-bound"
            
            let frString = self.arfDataManager.string(fromDate: self.game.start ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            let toString = self.arfDataManager.string(fromDate: self.game.end ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            self.actScheduleLabel.text = self.game.isNoExpiration == 1 ? "Always available" : "\(frString) - \(toString)"
            
            let dateCreatedString = self.arfDataManager.string(fromDate: self.game.dateCreated ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            self.actDateCreatedLabel.text = dateCreatedString
            
            let dateUpdatedString = self.arfDataManager.string(fromDate: self.game.dateUpdated ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            self.actDateUpdatedLabel.text = dateUpdatedString
            
            /// Clues
            guard let set = self.game.clues, let clues = set.allObjects as? [GameClue]  else {
                print("ERROR: Cant' retrieve game choice object!")
                return
            }
            
            var concatClues = ""
            
            for clue in clues {
                let c = clue.riddle ?? ""
                concatClues = "\(concatClues == "" ? "" : "\(concatClues), ")\(c)"
            }
            
            self.actCluesLabel.text = concatClues
        }
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func customBackButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

}
