//
//  ARFGAUserDetailsViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 30/11/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import SDWebImage

class ARFGAUserDetailsViewController: UIViewController {
    
    @IBOutlet var imageBackgroundView: UIView!
    @IBOutlet var userImage: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var userTypeLabel: UILabel!
    @IBOutlet var genderLabel: UILabel!
    @IBOutlet var actGenderLabel: UILabel!
    @IBOutlet var birthdateLabel: UILabel!
    @IBOutlet var actBirthdateLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var actAddressLabel: UILabel!
    @IBOutlet var mobileLabel: UILabel!
    @IBOutlet var actMobileLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var actEmailLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var actUsernameLabel: UILabel!
    @IBOutlet var passwordLabel: UILabel!
    @IBOutlet var actPasswordLabel: UILabel!
    @IBOutlet var dateCreatedLabel: UILabel!
    @IBOutlet var actDateCreatedLabel: UILabel!
    @IBOutlet var dateUpdatedLabel: UILabel!
    @IBOutlet var actDateUpdatedLabel: UILabel!
    
    var user: User!
    var isReview = false
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Render user details
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
        self.navigationController?.navigationBar.barTintColor = ARFConstants.color.GAV_NAV_USR_MOD
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        self.title = isReview ? "Review for Approval" : "User Details"
        
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
        if self.user != nil {
            self.nameLabel.text = self.user.middleName ?? "" == "" ? "\(self.user.firstName ?? "") \(self.user.lastName ?? "")" : "\(self.user.firstName ?? "") \(self.user.middleName ?? "") \(self.user.lastName ?? "")"
            self.userTypeLabel.text = self.user.type == 0 ? "Administrator" : self.user.type == 1 ? "Teacher" : "Student"
            self.actGenderLabel.text = self.user.gender == 0 ? "Male" : "Female"
            self.actBirthdateLabel.text = self.user.birthdate ?? ""
            self.actAddressLabel.text = self.user.address ?? ""
            self.actMobileLabel.text = self.user.mobile ?? ""
            self.actEmailLabel.text = self.user.email ?? ""
            self.actUsernameLabel.text = self.user.username ?? ""
            self.actPasswordLabel.text = self.user.password ?? ""
            self.actDateCreatedLabel.text = self.arfDataManager.string(fromDate: self.user.dateCreated ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            self.actDateUpdatedLabel.text = self.arfDataManager.string(fromDate: self.user.dateUpdated ?? Date(), format: ARFConstants.timeFormat.CLIENT)
            self.userImage.sd_setImage(with: URL(string: self.user.imageUrl ?? ""), completed: { (image, error, type, url) in
                self.userImage.image = image != nil ? image! : ARFConstants.image.GEN_UNKNOWN_USER
            })
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
