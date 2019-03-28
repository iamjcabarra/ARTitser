//
//  ARFGPSidekickDetailsViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 14/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit

class ARFGPSidekickDetailsViewController: UIViewController {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var cancelButton: UIButton!

    @IBOutlet var sidekickNameLabel: UILabel!
    @IBOutlet var sidekickLevelLabel: UILabel!
    @IBOutlet var sidekickPointsLabel: UILabel!
    @IBOutlet var sidekickSkillALevelLabel: UILabel!
    @IBOutlet var sidekickSkillADescriptionLabel: UILabel!
    @IBOutlet var sidekickSkillBLevelLabel: UILabel!
    @IBOutlet var sidekickSkillBDescriptionLabel: UILabel!
    @IBOutlet var sidekickSkillCLevelLabel: UILabel!
    @IBOutlet var sidekickSkillCDescriptionLabel: UILabel!
    @IBOutlet var sidekickSkillDLevelLabel: UILabel!
    @IBOutlet var sidekickSkillDDescriptionLabel: UILabel!
    @IBOutlet var sidekickSkillELevelLabel: UILabel!
    @IBOutlet var sidekickSkillEDescriptionLabel: UILabel!

    @IBOutlet var bottomView: UIView!
    @IBOutlet var sidekickImageView: UIView!
    @IBOutlet var sidekickSkillAlineView: UIView!
    @IBOutlet var sidekickSkillBlineView: UIView!
    @IBOutlet var sidekickSkillCLineView: UIView!
    @IBOutlet var sidekickSkillDLineView: UIView!
    @IBOutlet var sidekickSkillELineView: UIView!
    
    @IBOutlet var sidekickImage: UIImageView!
    @IBOutlet var sidekickSkillAImage: UIImageView!
    @IBOutlet var sidekickSkillBImage: UIImageView!
    @IBOutlet var sidekickSkillCImage: UIImageView!
    @IBOutlet var sidekickSkillDImage: UIImageView!
    @IBOutlet var sidekickSkillEImage: UIImageView!
    
    @IBOutlet var sidekickSkillAProgress: UIProgressView!
    @IBOutlet var sidekickSkillBProgress: UIProgressView!
    @IBOutlet var sidekickSkillCProgress: UIProgressView!
    @IBOutlet var sidekickSkillDProgress: UIProgressView!
    @IBOutlet var sidekickSkillEProgress: UIProgressView!
    
    var sidekick: Sidekick!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Drop shadow
        self.sidekickImageView.addShadow(offset: CGSize(width: -1, height: 1), color: .darkGray, radius: 1, opacity: 1)
        
        /// Configure buttons
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        
        /// Render sidekick details
        self.renderData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Data Rendering
    
    /// Binds data with controller's view ui objects
    fileprivate func renderData() {
        if self.sidekick != nil {
            let imageA = ARFConstants.image.GPV_SIDEKICK_A
            let imageB = ARFConstants.image.GPV_SIDEKICK_B
            let points = self.sidekick.points
            
            self.sidekickImage.image = self.sidekick.type == 0 ? imageA : imageB
            self.sidekickNameLabel.text = self.sidekick.name ?? ""
            self.sidekickPointsLabel.text = "\(self.sidekick.points)"
            self.sidekickLevelLabel.text = "Level \(self.sidekick.level)"
            self.sidekickSkillAProgress.progress = Float(points) / ARFConstants.sidekick.SKILL_A_DIVISOR
            self.sidekickSkillBProgress.progress = Float(points) / ARFConstants.sidekick.SKILL_B_DIVISOR
            self.sidekickSkillCProgress.progress = Float(points) / ARFConstants.sidekick.SKILL_C_DIVISOR
            self.sidekickSkillDProgress.progress = Float(points) / ARFConstants.sidekick.SKILL_D_DIVISOR
            self.sidekickSkillEProgress.progress = Float(points) / ARFConstants.sidekick.SKILL_E_DIVISOR
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

}
