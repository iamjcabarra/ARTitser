//
//  ARFGPSidekickWelcomeViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 06/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import FLAnimatedImage

protocol ARFGPSidekickWelcomeViewControllerDelegate: class {
    func showClassView()
}

class ARFGPSidekickWelcomeViewController: UIViewController {
    
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var selectedSidekickImage: FLAnimatedImageView!
    @IBOutlet var messageView: UIView!
    @IBOutlet var playerNameLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var letsGoButton: UIButton!
    
    weak var delegate: ARFGPSidekickWelcomeViewControllerDelegate?
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
        
        /// Set player's name
        self.playerNameLabel.text = "Welcome, \(self.arfDataManager.loggedUserFirstName)!"
        
        /// Handle button event
        self.letsGoButton.addTarget(self, action: #selector(self.letsGoButtonAction(_:)), for: .touchUpInside)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Button Event Handlers

    /// Presents class list view as user clicks on next
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func letsGoButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true) { self.delegate?.showClassView() }
    }

}
