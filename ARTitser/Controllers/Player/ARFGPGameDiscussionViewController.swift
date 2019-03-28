//
//  ARFGPGameDiscussionViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 10/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import FLAnimatedImage
import AVFoundation

class ARFGPGameDiscussionViewController: UIViewController, ARFGPGamePlayViewControllerDelegate {
    
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var sidekickImage: FLAnimatedImageView!
    @IBOutlet var discussionLabel: UILabel!
    @IBOutlet var actDiscussionLabel: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var cluesLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var beginButton: UIButton!
    @IBOutlet var ttsButton: UIButton!
    @IBOutlet var mechanicsButton: UIButton!
    @IBOutlet var discussonButton: UIButton!
    
    var classId: Int64 = 0
    var game: Game!
    
    fileprivate var speechSynthesizer = AVSpeechSynthesizer()
    fileprivate var isSidekickMale = true
    fileprivate var hasShownMechanics = false
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Render animated sidekick
//        let entity = ARFConstants.entity.SIDEKICK
//        let predicate = self.arfDataManager.predicate(forKeyPath: "ownedBy", exactValue: "\(self.arfDataManager.loggedUserId)")
//        if let sidekick = self.arfDataManager.db.retrieveObject(forEntity: entity, filteredBy: predicate) as? Sidekick {
//            let selectedSidekickType = sidekick.type
//            let sidekickALocation = Bundle.main.path(forResource: "sk_0001", ofType: "gif") ?? ""
//            let sidekickBLocation = Bundle.main.path(forResource: "sk_0002", ofType: "gif") ?? ""
//            let skaLocation = selectedSidekickType == 0 ? sidekickALocation : sidekickBLocation
//            if let data = NSData(contentsOfFile: skaLocation) { self.sidekickImage.animatedImage = FLAnimatedImage(animatedGIFData: data as Data) }
//            self.isSidekickMale = selectedSidekickType == 0 ? true : false
//        }
        
        let sidekickLocation = Bundle.main.path(forResource: "sk_0001", ofType: "gif") ?? ""
        if let data = NSData(contentsOfFile: sidekickLocation) { self.sidekickImage.animatedImage = FLAnimatedImage(animatedGIFData: data as Data) }
        
        /// Handle button events
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        self.beginButton.addTarget(self, action: #selector(self.beginButtonAction(_:)), for: .touchUpInside)
        self.ttsButton.addTarget(self, action: #selector(self.ttsButtonAction(_:)), for: .touchUpInside)
//        self.mechanicsButton.addTarget(self, action: #selector(self.mechanicsButtonAction(_:)), for: .touchUpInside)
        self.discussonButton.addTarget(self, action: #selector(self.discussionButtonAction(_:)), for: .touchUpInside)
        
        /// Render game details
        self.renderData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
//        /// Present onboarding mechanics
//        if !self.hasShownMechanics {
//            self.mechanicsButtonAction(nil)
//            self.hasShownMechanics = true
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        /// Stop speech synthesizer
        self.speechSynthesizer.stopSpeaking(at: .immediate)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Data Rendering
    
    /// Binds data with controller's view ui objects.
    fileprivate func renderData() {
        if self.game != nil {
            self.actDiscussionLabel.text = self.game.discussion ?? ""
            self.pointsLabel.text = "\(self.game.totalPoints) \(self.game.totalPoints > 1 ? "Points" : "Point")"
            self.cluesLabel.text = "\(self.game.clues?.count ?? 0) \(self.game.clues?.count ?? 0 > 1 ? "Questions" : "Question")"
            let timeString = self.game.isTimeBound == 1 ? "\(self.game.minutes) \(self.game.minutes > 1 ? "Minutes" : "Minute")" : "Open Time"
            self.timeLabel.text = timeString
            ///self.ttsButtonAction(nil)
        }
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Shows actual game view as user clicks on
    /// begin button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func beginButtonAction(_ sender: UIButton) {
        if self.game != nil {
            self.speechSynthesizer.stopSpeaking(at: .immediate)
            let data: [String: Any] = ["game": self.game]
            self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_GAME_PLAY_VIEW, sender: data)
        }
    }
    
    /// Voices out game's discussion.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func ttsButtonAction(_ sender: UIButton?) {
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: self.game.discussion ?? "")
        let language = self.isSidekickMale ? "en-gb" : "en-US"
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        self.speechSynthesizer.speak(utterance)
    }
    
//    /// Presents game mechanics view.
//    ///
//    /// - parameter sender: A UIButton
//    @objc fileprivate func mechanicsButtonAction(_ sender: UIButton?) {
//        self.speechSynthesizer.stopSpeaking(at: .immediate)
//        let storyboard = UIStoryboard(name: "ARFGPStoryboard", bundle: nil)
//        let pvc = storyboard.instantiateViewController(withIdentifier: "arfOnboardingMechanics") as! ARFGPMechanicsViewController
//        pvc.modalPresentationStyle = .overCurrentContext
//        pvc.modalTransitionStyle = .crossDissolve
//        self.present(pvc, animated: true, completion: nil)
//    }
    
    /// Presents discussion view with AR environment.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func discussionButtonAction(_ sender: UIButton?) {
        if let treasureObject = self.game.treasure {
            self.speechSynthesizer.stopSpeaking(at: .immediate)
            let data: [String: Any] = ["gameTreasure": treasureObject]
            self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_TREASURE_AR_VIEW, sender: data)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_GAME_PLAY_VIEW {
            guard let data = sender as? [String: Any], let game = data["game"] as? Game else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gamePlayView = segue.destination as! ARFGPGamePlayViewController
            gamePlayView.classId = self.classId
            gamePlayView.game = game
            gamePlayView.delegate = self
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_TREASURE_AR_VIEW {
            guard let data = sender as? [String: Any], let treasure = data["gameTreasure"] as? GameTreasure else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let treasure3DView = segue.destination as! ARFGPGameTreasure3dViewController
            treasure3DView.treasure = treasure
        }
        
    }
    
    // MARK: - ARFGPGamePlayViewControllerDelegate
    
    func quitGame() {
        self.dismiss(animated: true, completion: nil)
    }

}
