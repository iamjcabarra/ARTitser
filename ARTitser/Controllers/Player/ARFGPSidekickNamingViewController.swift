//
//  ARFGPSidekickNamingViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 06/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import PKHUD
import FLAnimatedImage

class ARFGPSidekickNamingViewController: UIViewController, UITextFieldDelegate, ARFGPSidekickWelcomeViewControllerDelegate {
    
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var selectedSidekickImage: FLAnimatedImageView!
    @IBOutlet var nameTextField: UITextField!
    
    var sidekickId: Int64 = 0
    var selectedSidekickType: Int64 = 0
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Render animated sidekick
        let sidekickALocation = Bundle.main.path(forResource: "sk_0001", ofType: "gif") ?? ""
        let sidekickBLocation = Bundle.main.path(forResource: "sk_0002", ofType: "gif") ?? ""
        let skaLocation = self.selectedSidekickType == 0 ? sidekickALocation : sidekickBLocation
        if let data = NSData(contentsOfFile: skaLocation) { self.selectedSidekickImage.animatedImage = FLAnimatedImage(animatedGIFData: data as Data) }
        
        /// Set delegate for text field
        self.nameTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        /// Decorate navigation bar
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
        self.navigationController?.navigationBar.barTintColor = ARFConstants.color.GPV_NAV_DASHBOARD
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        self.title = "Name Your Sidekick"
        
        /// Configure back button
        let backButton = UIButton(type: UIButtonType.custom)
        backButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        backButton.showsTouchWhenHighlighted = true
        backButton.setImage(ARFConstants.image.GEN_CHEVRON, for: UIControlState())
        let backButtonAction = #selector(self.backButtonAction(_:))
        backButton.addTarget(self, action: backButtonAction, for: .touchUpInside)
        
        /// Add button to the left navigation bar
        let backButtonItem = UIBarButtonItem(customView: backButton)
        self.navigationItem.leftBarButtonItem = backButtonItem
        
        /// Configure next button
        let nextButton = UIButton(type: UIButtonType.custom)
        nextButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        nextButton.showsTouchWhenHighlighted = true
        nextButton.setImage(ARFConstants.image.GEN_CHEVRON_NEXT, for: UIControlState())
        let nextButtonAction = #selector(self.nextButtonAction(_:))
        nextButton.addTarget(self, action: nextButtonAction, for: .touchUpInside)
        
        /// Add button to the right navigation bar
        let nextButtonItem = UIBarButtonItem(customView: nextButton)
        self.navigationItem.rightBarButtonItem = nextButtonItem
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /// Requests create a new sidekick. If succeeded, it
    /// then presents the welcome view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func nextButtonAction(_ sender: UIButton) {
        let title = "Oops!"
        
        if self.nameTextField.text != "" {
            let neKeys = ["type", "name", "level", "points", "ownedBy"]
            let entity = ARFConstants.entity.DEEP_COPY_SIDEKICK
            let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.sidekickId)")
            
            if self.arfDataManager.doesEntity(entity, filteredBy: predicate, containsEmptyValueForRequiredKeys: neKeys) {
                DispatchQueue.main.async {
                    let subtitle = "Please name your sidekick to continue."
                    HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                        self.nameTextField.becomeFirstResponder()
                    })
                }
                
                return
            }
            
            let rfKeys = ["type", "name", "level", "points", "ownedBy"]
            let body = self.arfDataManager.assemblePostData(fromEntity: entity, filteredBy: predicate, requiredKeys: rfKeys)
            
            if body != nil {
                HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
                
                self.arfDataManager.requestCreateSidekick(withBody: body!, completion: { (result) in
                    let status = result!["status"] as! Int
                    
                    if status == 0 {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let data: [String: Any] = ["selectedSidekickType": self.selectedSidekickType]
                            self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_SIDEKICK_WELCOME_VIEW, sender: data)
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = result!["message"] as! String
                            HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                        }
                    }
                })
            }
            else {
                DispatchQueue.main.async {
                    let subtitle = ARFConstants.message.DEFAULT_ERROR
                    HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                }
            }
        }
        else {
            DispatchQueue.main.async {
                let subtitle = "Name your sidekick to continue."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
            }
        }
    }
    
    // MARK: - Saving Local Changes
    
    /// Saves data in core data.
    ///
    /// - parameters:
    ///     - entity    : A String identifying core data entity
    ///     - predicate : A NSPredicate identifying filter
    ///     - data      : A Dictionary identifying data to be saved
    ///     - completion: A completion handler
    fileprivate func saveChangedData(forEntity entity: String, predicate: NSPredicate, data: [String: Any], completion: @escaping (_ doneBlock: Bool) -> Void) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            let success = self.arfDataManager.db.updateObjects(forEntity: entity, filteredBy: predicate, withData: data)
            completion(success)
        }
    }
    
    // MARK: - Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        /// Limit acceptable number of characters to 255
        if textField != self.nameTextField && newText.count > 255 { return false }
        
        /// Save to core data
        let data: [String: Any] = ["name": newText]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.sidekickId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_SIDEKICK, predicate: predicate, data: data) { (success) in }
        
        return true
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_SIDEKICK_WELCOME_VIEW {
            guard let data = sender as? [String: Any], let selectedSidekickType = data["selectedSidekickType"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let sidekickWelcomeView = segue.destination as! ARFGPSidekickWelcomeViewController
            sidekickWelcomeView.selectedSidekickType = selectedSidekickType
            sidekickWelcomeView.delegate = self
        }
        
    }

    // MARK: - ARFGPSidekickWelcomeViewControllerDelegate
    
    func showClassView() {
        if let nc = self.navigationController {
            let viewControllers: [UIViewController] = nc.viewControllers
            for vc in viewControllers {
                if vc is ARFGPClassViewController { nc.popToViewController(vc, animated: true) }
            }
        }
    }
 
}
