//
//  ARFGPGameTreasureViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 10/03/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import FLAnimatedImage
import AVFoundation
import PKHUD

protocol ARFGPGameTreasureViewControllerDelegate: class {
    func finish(_ finish: Bool, points: Int64, showResultView: Bool)
}

class ARFGPGameTreasureViewController: UIViewController, UITextFieldDelegate, ARFGPGameTreasure3dViewControllerDelegate {
    
    @IBOutlet var sidekickImage: FLAnimatedImageView!
    @IBOutlet var primaryView: UIView!
    @IBOutlet var pointsView: UIView!
    @IBOutlet var pointsMessageLabel: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var attemptsView: UIView!
    @IBOutlet var attemptsLabel: UILabel!
    @IBOutlet var discussionLabel: UILabel!
    @IBOutlet var answerTextField: UITextField!
    @IBOutlet var lineView: UIView!
    @IBOutlet var submitAnswerButton: UIButton!
    @IBOutlet var noteLabel: UILabel!
    @IBOutlet var cluesLabel: UILabel!
    @IBOutlet var resultView: UIView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var totalScoreLabel: UILabel!
    @IBOutlet var actTotalScoreLabel: UILabel!
    @IBOutlet var view3dView: UIView!
    @IBOutlet var view3dButton: UIButton!
    
    weak var delegate: ARFGPGameTreasureViewControllerDelegate?
    
    var classId: Int64 = 0
    var gameTreasure: GameTreasure!
    var subTotalPoints: Int64 = 0
    var clues = ""
    
    fileprivate var audioPlayer: AVAudioPlayer!
    fileprivate var speechSynthesizer = AVSpeechSynthesizer()
    fileprivate var attempts: Int64 = 0
    fileprivate var points: Int64 = 0
    fileprivate var correctMessages = ["Indescribable!", "Wonderful!", "Fantastic!", "Incredible!", "Unbelievable!"]
    fileprivate var wrongMessages = ["Incorrect", "Wrong", "Mistaken", "You've no luck", "I'm sorry"]
    fileprivate var isSidekickMale = false
    fileprivate var isSuccessful = false
    
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
        
        /// Configure background view
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        
        /// Set number of attempts
        self.attemptsLabel.text = "Attempt: \(self.attempts)"
        
        /// Set discussion
        self.discussionLabel.text = self.gameTreasure.claimingQuestion ?? ""
        
        /// Set note message
        self.noteLabel.text = self.gameTreasure.isCaseSensitive == 1 ? "Note: Answer is case sensitive." : ""
        
        /// Hide other views
        self.pointsView.isHidden = true
        self.resultView.isHidden = true
        
        /// Set other details
        self.cluesLabel.text = "CLUES: \(self.clues)"
        self.messageLabel.text = "Wow! You just finished the game by unlocking the hidden treasure!"
        self.actTotalScoreLabel.text = "\(self.subTotalPoints)"
        
        /// Handle button events
        self.submitAnswerButton.addTarget(self, action: #selector(self.submitAnswerButtonAction(_:)), for: .touchUpInside)
        self.view3dButton.addTarget(self, action: #selector(self.view3DButtonAction(_:)), for: .touchUpInside)
        
        /// Set delegate for text field
        self.answerTextField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    // MARK: - Background Music Handler
    
    /// Plays correct music.
    fileprivate func playCorrectMusic() {
        if let audioPath = Bundle.main.path(forResource: "correct_001", ofType: "wav"), let audioUrl = URL(string: audioPath) {
            do {
                if self.audioPlayer != nil { self.audioPlayer.stop() }
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
                self.audioPlayer.play()
            }
            catch {
                print("ERROR: Can't play correct music!")
            }
        }
    }
    
    /// Plays wrong music.
    fileprivate func playWrongMusic() {
        if let audioPath = Bundle.main.path(forResource: "wrong_001", ofType: "wav"), let audioUrl = URL(string: audioPath) {
            do {
                if self.audioPlayer != nil { self.audioPlayer.stop() }
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
                self.audioPlayer.play()
            }
            catch {
                print("ERROR: Can't play wrong music!")
            }
        }
    }
    
    // MARK: - Handle Speech Synthesizer
    
    /// Speaks out message for correct or
    /// wrong answer.
    fileprivate func speak(_ isCorrect: Bool) {
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        let randomCorrectIndex = Int(arc4random_uniform(UInt32(UInt64(self.correctMessages.count))))
        let randomWrongIndex = Int(arc4random_uniform(UInt32(UInt64(self.wrongMessages.count))))
        let randomCorrectMessage = self.correctMessages[randomCorrectIndex]
        let randomWrongMessage = self.wrongMessages[randomWrongIndex]
        let string = isCorrect ? randomCorrectMessage : randomWrongMessage
        let utterance = AVSpeechUtterance(string: string)
        let language = self.isSidekickMale ? "en-gb" : "en-US"
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        self.speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Button Event Handlers
    
    @objc fileprivate func submitAnswerButtonAction(_ sender: UIButton) {
        let answer = self.answerTextField.text ?? ""
        
        if answer == "" {
            let message = "Please enter your answer on the text field provided to continue."
            HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in })
            self.answerTextField.resignFirstResponder()
            return
        }
        
        let isCaseSensitive = self.gameTreasure.isCaseSensitive == 1 ? true : false
        let claimingAnswers = self.gameTreasure.claimingAnswers ?? ""
        let encryptedAnswer = answer.md5()
        let encryptedClaimingAnswers = self.gameTreasure.encryptedClaimingAnswers ?? ""
        let sameAnswers = answer.lowercased() == claimingAnswers.lowercased() ? true : false
        let sameEncrytedAnswers = encryptedAnswer == encryptedClaimingAnswers ? true : false
        let isCorrect = isCaseSensitive ? sameEncrytedAnswers : sameAnswers
        
        self.speak(isCorrect)
        
        self.submitAnswerButton.isEnabled = !isCorrect
        self.submitAnswerButton.isUserInteractionEnabled = !isCorrect
        self.pointsView.isHidden = !isCorrect
        self.resultView.isHidden = !isCorrect
        
        self.attempts = self.attempts + 1
        let attemptString = self.attempts > 1 ? "Attempts" : "Attempt"
        self.attemptsLabel.text = "\(attemptString): \(self.attempts)"
        
        if isCorrect {
            self.points = self.gameTreasure.points / self.attempts
            self.pointsMessageLabel.text = self.points > 1 ? "Points" : "Point"
            self.pointsLabel.text = "\(self.points)"
            self.actTotalScoreLabel.text = "\(self.points + self.subTotalPoints)"
        }
        
        isCorrect ? self.playCorrectMusic() : self.playWrongMusic()
        self.answerTextField.textColor = isCorrect ? UIColor.green : UIColor.red
        self.answerTextField.resignFirstResponder()
    }
    
    /// Shows 3D treasure object in AR as user clicks
    /// on view 3D button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func view3DButtonAction(_ sender: UIButton) {
        let entityGameTreasure = ARFConstants.entity.GAME_TREASURE
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameTreasure.id)")
        let data: [String: Any] = ["gpClassId": "\(self.classId)",
            "gpGameId": "\(self.gameTreasure.gameId)",
            "gpIsDone": "1",
            "gpNumberOfAttempts": "\(self.attempts)",
            "gpPlayerId": "\(self.arfDataManager.loggedUserId)",
            "gpPlayerName": "\(self.arfDataManager.loggedUserFullName)",
            "gpPoints": "\(self.points)",
            "gpTreasureId": "\(self.gameTreasure.id)",
            "gpTreasureName": "\(self.gameTreasure.name ?? "")"
        ]
        
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.saveChangedData(forEntity: entityGameTreasure, predicate: predicate, data: data) { (success) in
            self.isSuccessful = success
            DispatchQueue.main.async { self.delegate?.finish(self.isSuccessful, points: self.points, showResultView: false) }
            
            if self.isSuccessful && self.gameTreasure != nil {
                self.arfDataManager.requestSubmitGameResult(forGameWithId: "\(self.gameTreasure.gameId)", completion: { (result) in
                    let status = result!["status"] as! Int
                    
                    if status == 0 {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let data: [String: Any] = ["gameTreasure": self.gameTreasure]
                            self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_TREASURE_AR_VIEW, sender: data)
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = result!["message"] as! String
                            HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                        }
                    }
                })
            }
            else {
                DispatchQueue.main.async {
                    HUD.hide()
                    let subtitle = ARFConstants.message.DEFAULT_ERROR
                    HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                }
            }
        }
    }
    
    // MARK: - Text Field Delegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.textColor = UIColor.white
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_TREASURE_AR_VIEW {
            guard let data = sender as? [String: Any], let treasure = data["gameTreasure"] as? GameTreasure else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let treasure3DView = segue.destination as! ARFGPGameTreasure3dViewController
            treasure3DView.treasure = treasure
            treasure3DView.delegate = self
        }
        
    }
    
    // MARK: - ARFGPGameTreasure3dViewControllerDelegate
    
    func showResultView() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: {
                self.delegate?.finish(self.isSuccessful, points: self.points, showResultView: true)
            })
        }
    }

}
