//
//  ARFGCTreasureDetailsViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 28/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGCTreasureDetailsViewController: UIViewController {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var actNameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var actDescriptionLabel: UILabel!
    @IBOutlet var imageLabel: UILabel!
    @IBOutlet var actImageLabel: UILabel!
    @IBOutlet var model3dLabel: UILabel!
    @IBOutlet var actModel3dLabel: UILabel!
    @IBOutlet var claimingQuestionLabel: UILabel!
    @IBOutlet var actClaimingQuestionLabel: UILabel!
    @IBOutlet var claimingAnswerLabel: UILabel!
    @IBOutlet var actClaimingAnswerLabel: UILabel!
    @IBOutlet var isCaseSensitiveLabel: UILabel!
    @IBOutlet var actIsCaseSensitiveLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var actLocationLabel: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var actPointsLabel: UILabel!
    @IBOutlet var dateCreatedLabel: UILabel!
    @IBOutlet var actDateCreatedLabel: UILabel!
    @IBOutlet var dateUpdatedLabel: UILabel!
    @IBOutlet var actDateUpdatedLabel: UILabel!

    var treasure: Treasure!
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Render treasure details
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
        self.navigationController?.navigationBar.barTintColor = ARFConstants.color.GCV_NAV_TRE_MOD
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        self.title = "Asset Details"
        
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
        if self.treasure != nil {
            self.actNameLabel.text = self.treasure.name ?? ""
            self.actDescriptionLabel.text = self.treasure.treasureDescription ?? ""
            self.actImageLabel.text = self.treasure.imageLocalName ?? ""
            self.actModel3dLabel.text = self.treasure.model3dLocalName ?? ""
            self.actClaimingQuestionLabel.text = self.treasure.claimingQuestion ?? ""
            self.actClaimingAnswerLabel.text = self.treasure.claimingAnswers ?? ""
            self.actIsCaseSensitiveLabel.text = self.treasure.isCaseSensitive == 1 ? "Yes" : "No"
            self.actLocationLabel.text = self.treasure.locationName ?? ""
            self.actPointsLabel.text = "\(self.treasure.points)"
            let dateCreatedString = self.arfDataManager.string(fromDate: self.treasure.dateCreated ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            self.actDateCreatedLabel.text = dateCreatedString
            let dateUpdatedString = self.arfDataManager.string(fromDate: self.treasure.dateUpdated ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            self.actDateUpdatedLabel.text = dateUpdatedString
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
