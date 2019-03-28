//
//  ARFGPSidekickSelectionViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 06/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import PKHUD
import FLAnimatedImage

class ARFGPSidekickSelectionViewController: UIViewController {
    
    @IBOutlet var dividerView: UIView!
    @IBOutlet var sidekickAView: UIView!
    @IBOutlet var sidekickBView: UIView!
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var sidekickAImage: FLAnimatedImageView!
    @IBOutlet var sidekickBImage: FLAnimatedImageView!
    @IBOutlet var sidekickAButton: UIButton!
    @IBOutlet var sidekickBButton: UIButton!
    
    var sidekickId: Int64 = 0
    var selectedSidekickType: Int64 = 0
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure initial settings for views
        self.sidekickAView.backgroundColor = UIColor(white: 0, alpha: 0.65)
        self.sidekickBView.backgroundColor = UIColor(white: 0, alpha: 0.35)
        
        /// Handle button events
        self.sidekickAButton.addTarget(self, action: #selector(self.sidekickAButtonAction(_:)), for: .touchUpInside)
        self.sidekickBButton.addTarget(self, action: #selector(self.sidekickBButtonAction(_:)), for: .touchUpInside)
        
        /// Render animated sidekicks
        let skaLocation = Bundle.main.path(forResource: "sk_0001", ofType: "gif") ?? ""
        if let data = NSData(contentsOfFile: skaLocation) { self.sidekickAImage.animatedImage = FLAnimatedImage(animatedGIFData: data as Data) }
        let skbLocation = Bundle.main.path(forResource: "sk_0002", ofType: "gif") ?? ""
        if let data = NSData(contentsOfFile: skbLocation) { self.sidekickBImage.animatedImage = FLAnimatedImage(animatedGIFData: data as Data) }
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
        self.title = "Select Your Sidekick"
        
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
    
    /// Presents name sidekick view if player has already
    /// selected a sidekick.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func nextButtonAction(_ sender: UIButton) {
        let data: [String: Any] = ["sidekickId": self.sidekickId, "selectedSidekickType": self.selectedSidekickType]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_SIDEKICK_NAMING_VIEW, sender: data)
    }
    
    /// Updates sidekick's type in core data as user clicks
    /// on sidekick button. If update succeeds, it then
    /// updates the ui.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func sidekickAButtonAction(_ sender: UIButton) {
        let entity = ARFConstants.entity.DEEP_COPY_SIDEKICK
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.sidekickId)")
        let data: [String: Any] = ["type": 0]
        self.saveChangedData(forEntity: entity, predicate: predicate, data: data) { (success) in
            if success {
                DispatchQueue.main.async {
                    self.selectedSidekickType = ARFConstants.sidekick.A
                    self.sidekickAView.backgroundColor = UIColor(white: 0, alpha: 0.65)
                    self.sidekickBView.backgroundColor = UIColor(white: 0, alpha: 0.35)
                }
            }
        }
    }
    
    /// Updates sidekick's type in core data as user clicks
    /// on sidekick button. If update succeeds, it then
    /// updates the ui.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func sidekickBButtonAction(_ sender: UIButton) {
        let entity = ARFConstants.entity.DEEP_COPY_SIDEKICK
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.sidekickId)")
        let data: [String: Any] = ["type": 1]
        self.saveChangedData(forEntity: entity, predicate: predicate, data: data) { (success) in
            if success {
                DispatchQueue.main.async {
                    self.selectedSidekickType = ARFConstants.sidekick.B
                    self.sidekickAView.backgroundColor = UIColor(white: 0, alpha: 0.35)
                    self.sidekickBView.backgroundColor = UIColor(white: 0, alpha: 0.65)
                }
            }
        }
    }
    
    /// Goes back to class view as user chooses to cancel
    /// selecting his sidekick.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func backButtonAction(_ sender: UIButton) {
        let message = "Are you sure you want to cancel selecting your sidekick? You cannot play games without a sidekick."
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let posAction = UIAlertAction(title: "Yes", style: .default) { (Alert) -> Void in
            DispatchQueue.main.async(execute: { self.navigationController?.popViewController(animated: true) })
        }
        
        let negAction = UIAlertAction(title: "No", style: .cancel) { (Alert) -> Void in
            DispatchQueue.main.async(execute: { alert.dismiss(animated: true, completion: nil) })
        }
        
        alert.addAction(posAction)
        alert.addAction(negAction)
        
        self.present(alert, animated: true, completion: nil)
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
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_SIDEKICK_NAMING_VIEW {
            guard let data = sender as? [String: Any], let sidekickId = data["sidekickId"] as? Int64, let selectedSidekickType = data["selectedSidekickType"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let sidekickNamingView = segue.destination as! ARFGPSidekickNamingViewController
            sidekickNamingView.sidekickId = sidekickId
            sidekickNamingView.selectedSidekickType = selectedSidekickType
        }
        
    }

}
