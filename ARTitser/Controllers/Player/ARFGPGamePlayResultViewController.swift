//
//  ARFGPGamePlayResultViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 12/03/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

protocol ARFGPGamePlayResultViewControllerDelegate: class {
    func goBackToGameListView()
}

class ARFGPGamePlayResultViewController: UIViewController {
    
    @IBOutlet var primaryView: UIView!
    @IBOutlet var gameOverLabel: UILabel!
    @IBOutlet var congratulatoryLabel: UILabel!
    @IBOutlet var actTotalPointsLabel: UILabel!
    @IBOutlet var totalPointsLabel: UILabel!
    @IBOutlet var homeImage: UIImageView!
    @IBOutlet var homeButton: UIButton!
    
    weak var delegate: ARFGPGamePlayResultViewControllerDelegate?
    
    var isTimeOut = false
    var totalPoints: Int64 = 0

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure background view
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        
        /// Set primary view color
        self.primaryView.backgroundColor = self.isTimeOut ? UIColor.red : UIColor(hex: "0458AB")
        
        /// Set text for game over label
        self.gameOverLabel.text = self.isTimeOut ? "Time's Up!" : "Done"
        
        /// Set congratulatory message
        let posMessage = "Congratulations!\nYou have successully finished the assessment!"
        let negMessage = "Sorry, but your time is already up."
        self.congratulatoryLabel.text = self.isTimeOut ? negMessage : posMessage
        
        /// Set total points
        self.actTotalPointsLabel.text = "\(self.totalPoints)"
        self.totalPointsLabel.text = "Total Points"
        
        /// Handle button event
        self.homeButton.addTarget(self, action: #selector(self.homeButtonAction(_:)), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Button Event Handler
    
    /// Goes back to the game list view as user
    /// clicks on home button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func homeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.delegate?.goBackToGameListView()
        }
    }

}
