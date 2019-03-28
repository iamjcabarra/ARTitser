//
//  ARFGACourseDetailsViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 07/11/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit

class ARFGACourseDetailsViewController: UIViewController {
    
    @IBOutlet var codeLabel: UILabel!
    @IBOutlet var actCodeLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var actTitleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var actDescriptionLabel: UILabel!
    @IBOutlet var unitLabel: UILabel!
    @IBOutlet var actUnitLabel: UILabel!
    @IBOutlet var dateCreatedLabel: UILabel!
    @IBOutlet var actDateCreatedLabel: UILabel!
    @IBOutlet var dateUpdatedLabel: UILabel!
    @IBOutlet var actDateUpdatedLabel: UILabel!
    
    var course: Course!
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Render course details
        self.renderData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Customize navigation
        self.customizeNavigationBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Custom Navigation Bar
    
    /// Customizes navigation controller's navigation
    /// bar.
    fileprivate func customizeNavigationBar() {
        /// Configure navigation bar
        self.navigationController?.navigationBar.barTintColor = ARFConstants.color.GAV_NAV_CRS_MOD
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        self.title = "Course Details"
        
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
        if self.course != nil {
            self.actCodeLabel.text = self.course.code ?? ""
            self.actTitleLabel.text = self.course.title ?? ""
            self.actDescriptionLabel.text = self.course.courseDescription ?? ""
            self.actUnitLabel.text = "\(self.course.unit)"
            let dateCreatedString = self.arfDataManager.string(fromDate: self.course.dateCreated ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            self.actDateCreatedLabel.text = dateCreatedString
            let dateUpdatedString = self.arfDataManager.string(fromDate: self.course.dateUpdated ?? Date(), format: ARFConstants.timeFormat.CLIENT)
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
