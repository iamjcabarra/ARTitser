//
//  ARFGPGamePauseViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 11/03/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

protocol ARFGPGamePauseViewControllerDelegate: class {
    func resumeGame()
}

class ARFGPGamePauseViewController: UIViewController {
    
    @IBOutlet var primaryView: UIView!
    @IBOutlet var gamePausedImage: UIImageView!
    @IBOutlet var gamePausedLabel: UILabel!
    @IBOutlet var resumeButton: UIButton!
    
    weak var delegate: ARFGPGamePauseViewControllerDelegate?
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /// Configure background view
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        
        /// Handle button event
        self.resumeButton.addTarget(self, action: #selector(self.resumeButtonAction(_:)), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Button Event Handler
    
    /// Dismisses view as user clicks on resume
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc func resumeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true) { self.delegate?.resumeGame() }
    }

}
