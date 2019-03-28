//
//  ARFGENPrimaryViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 10/11/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import PKHUD
import CryptoSwift

class ARFGENPrimaryViewController: UIViewController {
    
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var appLogoImage: UIImageView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var usernameView: UIView!
    @IBOutlet var passwordView: UIView!
    @IBOutlet var logInView: UIView!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var logInButton: UIButton!
    @IBOutlet var forgotPasswordLabel: UILabel!
    @IBOutlet var newUserLabel: UILabel!
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var versionLabel: UILabel!
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure views
        self.containerView.addShadow(offset: CGSize(width: -1, height: 1), color: .darkGray, radius: 1, opacity: 1)
        self.logInView.addShadow(offset: CGSize(width: -1, height: 1), color: .darkGray, radius: 1, opacity: 1)
        self.usernameView.layer.borderWidth = 0.5
        self.usernameView.layer.borderColor = UIColor(hex: "bababa").cgColor
        self.passwordView.layer.borderWidth = 0.5
        self.passwordView.layer.borderColor = UIColor(hex: "bababa").cgColor
        
        /// Configure text fields
        self.usernameTextField.setLeftPaddingPoints(10)
        self.usernameTextField.setRightPaddingPoints(10)
        self.usernameTextField.placeholder = "Username"
        self.passwordTextField.setLeftPaddingPoints(10)
        self.passwordTextField.setRightPaddingPoints(10)
        self.passwordTextField.placeholder = "Password"
        
        /// Configure listener for login button
        self.logInButton.addTarget(self, action: #selector(self.logInButtonAction(_:)), for: .touchUpInside)
        self.registerButton.addTarget(self, action: #selector(self.registerButtonAction(_:)), for: .touchUpInside)
        
        /// Register settings bundle
        self.registerSettingsBundle()
        
        /// Add observer for defaults
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ARFGENPrimaryViewController.defaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.usernameTextField.text = ""
        self.passwordTextField.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Button Event Handlers
    
    /// Requests for user authentication as user clicks
    /// on log in button. If request succeeded, it then
    /// redirects user to his designated storyboard.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func logInButtonAction(_ sender: UIButton) {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        let username = self.usernameTextField.text!.md5()
        let password = self.passwordTextField.text!.md5()
        
        self.arfDataManager.requestLoginUser(withUsername: username, andPassword: password) { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    HUD.hide()
                    let userType = self.arfDataManager.loggedUserType
                    let identifier = userType == 0 ? ARFConstants.segueIdentifier.GAV : userType == 1 ? ARFConstants.segueIdentifier.GCV : ARFConstants.segueIdentifier.GPV
                    self.performSegue(withIdentifier: identifier, sender: self)
                }
            }
            else {
                DispatchQueue.main.async {
                    HUD.hide()
                    let subtitle = result!["message"] as! String
                    HUD.flash(.labeledError(title: "Log In", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in})
                }
            }
        }
    }
    
    /// Presents user creation view as user clicks on
    /// registration button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func registerButtonAction(_ sender: UIButton) {
        self.arfDataManager.deepCopyUserObject(nil, owner: self.arfDataManager.loggedUserId, isCreation: true, isRegistration: true) { (result) in
            if result != nil {
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "ARFGAStoryboard", bundle: nil)
                    let pvc = storyboard.instantiateViewController(withIdentifier: "registerNewUser") as! ARFGAUserCreationViewController
                    pvc.user = result!["user"] as! DeepCopyUser
                    pvc.isCreation = true
                    pvc.isRegistration = true
                    pvc.modalPresentationStyle = .overCurrentContext
                    pvc.modalTransitionStyle = .coverVertical
                    self.present(pvc, animated: true, completion: nil)
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
    
    // MARK: - User Defaults
    
    /// Configures user defaults.
    fileprivate func registerSettingsBundle() {
        let appDefaults = [String: Any]()
        UserDefaults.standard.register(defaults: appDefaults)
        defaultsChanged()
    }
    
    /// Updates the value of server url in data manager as user changes
    /// server url in the app settings.
    @objc fileprivate func defaultsChanged() {
        if let url = UserDefaults.standard.string(forKey: "server_url_preference") {
            arfDataManager.serverUrl = url.trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }
    
}
