//
//  ARFGPGameClueViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 10/03/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import FLAnimatedImage
import AVFoundation

protocol ARFGPGameClueViewControllerDelegate: class {
    func proceed(_ proceed: Bool, points: Int64, clue: String)
}

class ARFGPGameClueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var sidekickImage: FLAnimatedImageView!
    @IBOutlet var primaryView: UIView!
    @IBOutlet var attemptsView: UIView!
    @IBOutlet var attemptsLabel: UILabel!
    @IBOutlet var pointsView: UIView!
    @IBOutlet var pointsMessageLabel: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var clueRiddleLabel: UILabel!
    @IBOutlet var clueChoiceTableView: UITableView!
    @IBOutlet var resultView: UIView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var clueMessageLabel: UILabel!
    @IBOutlet var clueLabel: UILabel!
    @IBOutlet var proceedButtonView: UIView!
    @IBOutlet var proceedButton: UIButton!

    weak var delegate: ARFGPGameClueViewControllerDelegate?
    
    var classId: Int64 = 0
    var gameClue: GameClue!
    var isLast = true
    
    fileprivate var audioPlayer: AVAudioPlayer!
    fileprivate var speechSynthesizer = AVSpeechSynthesizer()
    fileprivate var letters = ["A", "B", "C", "D"]
    fileprivate var attempts = 0
    fileprivate var points: Int64 = 0
    fileprivate var clue = ""
    fileprivate var hasBeenAnsweredCorrectly = false
    fileprivate var correctMessages = ["Correct!", "Great!", "Fantastic!"]
    fileprivate var wrongMessages = ["Incorrect!", "Sorry!", "Mistakem"]
    fileprivate var isSidekickMale = true
    
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
        
        /// Set estimated height for tableview cells
        self.clueChoiceTableView.estimatedRowHeight = 65.0
        
        /// Make tableview cell's height dynamic
        self.clueChoiceTableView.rowHeight = UITableViewAutomaticDimension
        
        /// Remove extra padding on the top of the table view
        self.clueChoiceTableView.contentInset = UIEdgeInsetsMake(-35, 0, 0, 0);
        
        /// Configure background view
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        
        /// Set number of attempts
        self.attemptsLabel.text = "Attempt: \(self.attempts)"
        
        /// Set riddle
        self.clueRiddleLabel.text = self.gameClue.riddle ?? ""
        
        /// Hide other views
        self.pointsView.isHidden = true
        self.resultView.isHidden = true
        
        /// Set other clue details
        self.messageLabel.text = "Congratulations!\nYou just answered the question correctly!"
        self.clueLabel.text = self.gameClue.clue ?? ""
        
        /// Configure proceed button
        let title = "Next Question"//self.isLast ? "Find Treasure" : "Find Next Clue"
        self.proceedButton.setTitle(title, for: .normal)
        self.proceedButton.setTitle(title, for: .highlighted)
        self.proceedButton.setTitle(title, for: .selected)
        
        /// Handle button event
        self.proceedButton.addTarget(self, action: #selector(self.proceedButtonAction(_:)), for: .touchUpInside)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        /// Stop speech synthesizer
        self.speechSynthesizer.stopSpeaking(at: .immediate)
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
    
    /// Saves changes in game clue and goes back to the
    /// game play view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func proceedButtonAction(_ sender: UIButton) {
        let entity = ARFConstants.entity.GAME_CLUE
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(gameClue.id)")
        let data: [String: Any] = ["gpClassId": "\(self.classId)",
            "gpPlayerId": "\(self.arfDataManager.loggedUserId)",
            "gpPlayerName": "\(self.arfDataManager.loggedUserFullName)",
            "gpGameId": "\(self.gameClue.gameId)",
            "gpClueId": "\(self.gameClue.id)",
            "gpClueName": "\(self.gameClue.clue ?? "")",
            "gpNumberOfAttempts": "\(self.attempts)",
            "gpPoints": "\(self.points)",
            "gpIsDone": "1"
        ]
        
        self.saveChangedData(forEntity: entity, predicate: predicate, data: data, completion: { (success) in
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: {
                    self.delegate?.proceed(success, points: self.points, clue: self.clue)
                })
            }
        })
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sectionCount = fetchedResultsController.sections?.count else { return 0 }
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionData = fetchedResultsController.sections?[section] else { return 0 }
        return sectionData.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.GAME_CLUE_CHOICE, for: indexPath) as! ARFGPGameClueChoiceTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ARFGPGameClueChoiceTableViewCell, atIndexPath indexPath: IndexPath) {
        let choiceObject = fetchedResultsController.object(at: indexPath) as! GameClueChoice
        cell.letterChoiceLabel.text = "\(self.letters[indexPath.row])."
        cell.choiceLabel.text = "\(choiceObject.choiceStatement ?? "")"
        cell.selectionStyle = .none
        
        var color = UIColor.white
        
        if choiceObject.gpHasBeenSelected == 1 {
            if choiceObject.isCorrect == 1 { color = UIColor.green }
            else { color = UIColor.red }
        }
        
        cell.backView.backgroundColor = color
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.hasBeenAnsweredCorrectly { return }
        
        let choiceObject = fetchedResultsController.object(at: indexPath) as! GameClueChoice
        let isCorrect = choiceObject.isCorrect == 1 ? true : false
        let entity = ARFConstants.entity.GAME_CLUE_CHOICE
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(choiceObject.id)")
        let data: [String: Any] = ["gpHasBeenSelected": 1]
        
        self.speak(isCorrect)
        
        self.saveChangedData(forEntity: entity, predicate: predicate, data: data, completion: { (success) in
            if success  {
                DispatchQueue.main.async {
                    self.attempts = self.attempts + 1
                    let attemptString = self.attempts > 1 ? "Attempts" : "Attempt"
                    self.attemptsLabel.text = "\(attemptString): \(self.attempts)"
                    
                    self.reloadFetchedResultsController()
                    self.hasBeenAnsweredCorrectly = isCorrect
                    self.pointsView.isHidden = isCorrect ? false : true
                    self.resultView.isHidden = isCorrect ? false : true
                    
                    let poas = self.gameClue.pointsOnAttempts ?? ""
                    let pointList = poas.components(separatedBy: ",")
                
                    if pointList.count > 0 {
                        let index = self.attempts - 1 >= pointList.count ? 0 : self.attempts - 1
                        self.points = self.arfDataManager.intString(pointList[index])
                        self.pointsMessageLabel.text = self.points > 1 ? "Points" : "Point"
                        self.pointsLabel.text = "\(self.points)"
                    }
                    
                    isCorrect ? self.playCorrectMusic() : self.playWrongMusic()
                    if isCorrect { self.clue = self.gameClue.clue ?? "" }
                }
            }
        })
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.GAME_CLUE_CHOICE)
        fetchRequest.fetchBatchSize = 20
        
        let predicateA = self.arfDataManager.predicate(forKeyPath: "gameId", exactValue: "\(self.gameClue.gameId)")
        let predicateB = self.arfDataManager.predicate(forKeyPath: "clueId", exactValue: "\(self.gameClue.id)")
        let predicateC = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateA, predicateB])
        fetchRequest.predicate = predicateC
        
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: ctx!, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        
        _fetchedResultsController = frc
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch {
            abort()
        }
        
        return _fetchedResultsController!
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.clueChoiceTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            self.clueChoiceTableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.clueChoiceTableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.clueChoiceTableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.clueChoiceTableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath {
                if let cell = self.clueChoiceTableView.cellForRow(at: indexPath) {
                    self.configureCell(cell as! ARFGPGameClueChoiceTableViewCell, atIndexPath: indexPath)
                }
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.clueChoiceTableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.clueChoiceTableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.clueChoiceTableView.endUpdates()
    }
    
    func reloadFetchedResultsController() {
        self._fetchedResultsController = nil
        self.clueChoiceTableView.reloadData()
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
    }

}
