//
//  ARFGCClueDetailsViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 21/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGCClueDetailsViewController: UIViewController {
    
    @IBOutlet var riddleLabel: UILabel!
    @IBOutlet var actRiddleLabel: UILabel!
    @IBOutlet var choicesLabel: UILabel!
    @IBOutlet var actChoicesLabel: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var actPointsLabel: UILabel!
    @IBOutlet var attemptsLabel: UILabel!
    @IBOutlet var actAttemptsLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var actLocationLabel: UILabel!
    @IBOutlet var clueLabel: UILabel!
    @IBOutlet var actClueLabel: UILabel!
    @IBOutlet var dateCreatedLabel: UILabel!
    @IBOutlet var actDateCreatedLabel: UILabel!
    @IBOutlet var dateUpdatedLabel: UILabel!
    @IBOutlet var actDateUpdatedLabel: UILabel!
    
    var clue: Clue!
    
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
        self.navigationController?.navigationBar.barTintColor = ARFConstants.color.GCV_NAV_CLU_MOD
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        self.title = "Question Details"
        
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
        if self.clue != nil {
            self.actRiddleLabel.text = self.clue.riddle ?? ""
            self.actPointsLabel.text = "\(self.clue.points)"
            self.actLocationLabel.text = self.clue.locationName ?? ""
            self.actClueLabel.text = self.clue.clue ?? ""
            let dateCreatedString = self.arfDataManager.string(fromDate: self.clue.dateCreated ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            self.actDateCreatedLabel.text = dateCreatedString
            let dateUpdatedString = self.arfDataManager.string(fromDate: self.clue.dateUpdated ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            self.actDateUpdatedLabel.text = dateUpdatedString
            
            /// Choices
            guard let set = self.clue.choices, let choices = set.allObjects as? [ClueChoice]  else {
                print("ERROR: Cant' retrieve clue choice object!")
                return
            }
            
            var concatChoices = ""
            var counterX = 0
            var letters = ["A", "B", "C", "D"]
            
            for c in choices {
                let choiceStatement = self.arfDataManager.string(c.choiceStatement)
                let isCorrect = self.arfDataManager.intString("\(c.isCorrect)")
                let choiceString = "[\(letters[counterX])] \(choiceStatement)\(isCorrect == 1 ? " (Correct)" : "")"
                concatChoices = "\(concatChoices == "" ? "" : "\(concatChoices); ")\(choiceString)"
                counterX = counterX + 1
            }
            
            self.actChoicesLabel.text = concatChoices
            
            /// Points on Attempts
            let splittedPointsOnAttempts = self.clue.pointsOnAttempts!.components(separatedBy: ",")
            var pointsOnAttemptsFormatted = ""
            var counterY = 0
            
            for spoa in splittedPointsOnAttempts {
                pointsOnAttemptsFormatted = "\(pointsOnAttemptsFormatted == "" ? "" : "\(pointsOnAttemptsFormatted);") [\(counterY + 1)] \(spoa)"
                counterY = counterY + 1
            }
            
            self.actAttemptsLabel.text = pointsOnAttemptsFormatted
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
