//
//  ARFGCGameCreationViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 29/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD
import DatePickerDialog
import SDWebImage

protocol ARFGCGameCreationViewControllerDelegate: class {
    func requestUpdateView()
}

class ARFGCGameCreationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate,  UITextFieldDelegate, UITextViewDelegate, ARFGCGameTreasureSelectionViewControllerDelegate, ARFGCGameClueSelectionViewControllerDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var discussionLabel: UILabel!
    @IBOutlet var treasureLabel: UILabel!
    @IBOutlet var cluesLabel: UILabel!
    @IBOutlet var cluesReminderLabel: UILabel!
    @IBOutlet var totalPointsLabel: UILabel!
    @IBOutlet var timeLimitLabel: UILabel!
    @IBOutlet var scheduleLabel: UILabel!
    @IBOutlet var frLabel: UILabel!
    @IBOutlet var toLabel: UILabel!
    @IBOutlet var securityCodeLabel: UILabel!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var treasureTextField: UITextField!
    @IBOutlet var totalPointsTextField: UITextField!
    @IBOutlet var timeLimitTextField: UITextField!
    @IBOutlet var frTextField: UITextField!
    @IBOutlet var toTextField: UITextField!
    @IBOutlet var securityCodeTextField: UITextField!
    @IBOutlet var discussionTextField: UITextView!
    @IBOutlet var treasureButton: UIButton!
    @IBOutlet var addClueButton: UIButton!
    @IBOutlet var timeLimitButton: UIButton!
    @IBOutlet var notTimeBoundButton: UIButton!
    @IBOutlet var alwaysAvailableButton: UIButton!
    @IBOutlet var frButton: UIButton!
    @IBOutlet var toButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var processButton: UIButton!
    @IBOutlet var notTimeBoundImage: UIImageView!
    @IBOutlet var alwaysAvailableImage: UIImageView!
    @IBOutlet var cluesTableView: UITableView!
    
    weak var delegate: ARFGCGameCreationViewControllerDelegate?

    var gameId: Int64 = 0
    var isCreation = true
    
    fileprivate var game: DeepCopyGame!
    fileprivate var isTimeBound = false
    fileprivate var isAlwaysAvailable = true
    fileprivate var selectedClues: [Int64]? = nil

    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = self.isCreation ? "Create Lesson" : "Update Lesson"
        
        /// Hide empty place holder by default
        self.shouldShowEmptyPlaceholderView(false)
        
        /// Configure background color
        let backgroundColor = self.isCreation ? ARFConstants.color.GEN_CREATE_ACTION : ARFConstants.color.GEN_UPDATE_ACTION
        self.navigationBar.barTintColor = backgroundColor
        self.bottomView.backgroundColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Remove extra padding on the top of the table view
        self.cluesTableView.contentInset = UIEdgeInsetsMake(-35, 0, 0, 0);
        
        /// Configure text view
        self.discussionTextField.layer.borderWidth = 0.5
        self.discussionTextField.layer.borderColor = UIColor.lightGray.cgColor
        self.discussionTextField.layer.cornerRadius = 6
        
        /// Set delegate for text fields
        self.nameTextField.delegate = self
        self.securityCodeTextField.delegate = self
        self.discussionTextField.delegate = self
        
        /// Configure buttons
        self.treasureButton.addTarget(self, action: #selector(self.treasureButtonAction(_:)), for: .touchUpInside)
        self.addClueButton.addTarget(self, action: #selector(self.addClueButtonAction(_:)), for: .touchUpInside)
        self.timeLimitButton.addTarget(self, action: #selector(self.timeLimitButtonAction(_:)), for: .touchUpInside)
        self.notTimeBoundButton.addTarget(self, action: #selector(self.notTimeBoundButtonAction(_:)), for: .touchUpInside)
        self.alwaysAvailableButton.addTarget(self, action: #selector(self.alwaysAvailableButtonAction(_:)), for: .touchUpInside)
        self.frButton.addTarget(self, action: #selector(self.frButtonAction(_:)), for: .touchUpInside)
        self.toButton.addTarget(self, action: #selector(self.toButtonAction(_:)), for: .touchUpInside)
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        self.processButton.addTarget(self, action: #selector(self.processButtonAction(_:)), for: .touchUpInside)
        
        /// Render game details
        self.renderData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Data Rendering
    
    /// Binds data with controller's view ui objects.
    fileprivate func renderData() {
        let entity = ARFConstants.entity.DEEP_COPY_GAME
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameId)")
        
        guard let game = self.arfDataManager.db.retrieveObject(forEntity: entity, filteredBy: predicate) as? DeepCopyGame else {
            print("ERROR: Can't retrieve deep copy game!")
            self.dismiss(animated: true, completion: nil)
            return
        }

        self.game = game
        
        let treasurePointString = ""//self.game.treasurePoints > 1 ? "points" : "point"
        let actualTreasurePointString = "\(self.game.treasurePoints) \(treasurePointString)"
        let treasureName = self.game.treasureName ?? ""
        let actualTreasureName = treasureName == "" ? "" : "\(treasureName) (\(actualTreasurePointString))"
            
        self.nameTextField.text = self.game.name ?? ""
        self.discussionTextField.text = self.game.discussion ?? ""
        self.treasureTextField.text = actualTreasureName
        self.totalPointsTextField.text = "\(self.game.totalPoints)"
        self.securityCodeTextField.text = self.game.securityCode ?? ""
        
        self.isTimeBound = self.game.isTimeBound == 1 ? true : false
        self.isAlwaysAvailable = self.game.isNoExpiration == 1 ? true : false
        
        let timeLimitString = "\(self.game.minutes) \(self.game.minutes > 1 ? "minutes" : "minute")"
        self.timeLimitTextField.text = self.isTimeBound ? timeLimitString : ""
        
        let imageA = ARFConstants.image.GEN_CB_SELECTED
        let imageB = ARFConstants.image.GEN_CB_UNSELECTED
        let format = ARFConstants.timeFormat.CLIENT
        let frDateString = self.arfDataManager.string(fromDate: self.game.start ?? Date(), format: format)
        let toDateString = self.arfDataManager.string(fromDate: self.game.end ?? Date(), format: format)
 
        self.frTextField.text = self.isAlwaysAvailable ? "" : frDateString
        self.toTextField.text = self.isAlwaysAvailable ? "" : toDateString
        self.notTimeBoundImage.image = self.isTimeBound ? imageB : imageA
        self.alwaysAvailableImage.image = self.isAlwaysAvailable ? imageA : imageB
        
        self.reloadFetchedResultsController()
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
    
    // MARK: - Check for Required Fields
    
    /// Changes background color of required fields to red
    /// if empty or white if not.
    fileprivate func checkRequiredFields() {
        let posColor = UIColor(hex: "ffffff")
        let negColor = UIColor(hex: "f9e8e8")

        self.nameTextField.backgroundColor = self.nameTextField.text == "" ? negColor : posColor
        self.treasureTextField.backgroundColor = self.treasureTextField.text == "" ? negColor : posColor
        self.discussionTextField.backgroundColor = self.discussionTextField.text == "" ? negColor : posColor
        self.timeLimitTextField.backgroundColor = self.game.isTimeBound == 0 ? posColor :  self.timeLimitTextField.text == "" ? negColor : posColor
        self.frTextField.backgroundColor = self.game.isNoExpiration == 1 ? posColor : self.frTextField.text == "" ? negColor : posColor
        self.toTextField.backgroundColor = self.game.isNoExpiration == 1 ? posColor : self.toTextField.text == "" ? negColor : posColor
    }
    
    // MARK: - Button Event Handlers
    
    /// Presents treasure selection view as user clicks
    /// on game treasure button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func treasureButtonAction(_ sender: UIButton) {
        let data: [String: Any] = ["gameId":self.gameId, "treasureId": self.game.treasureId]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_GAME_TREASURE_SELECTION_VIEW, sender: data)
    }
    
    /// Presents clue selection view as user clicks
    /// on add game clue button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func addClueButtonAction(_ sender: UIButton) {
        let clueIds = self.arfDataManager.string(self.game.clueIds)
        self.selectedClues = [Int64]()
        let clueList = clueIds.components(separatedBy: ",")
        for c in clueList { self.selectedClues?.append(self.arfDataManager.intString(c)) }
        let data: [String: Any] = ["gameId":self.game.id]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_GAME_CLUE_SELECTION_VIEW, sender: data)
    }
    
    /// Presents Date Picker Dialog where user can set
    /// time limit for the game. Selected time will be
    /// converted to minutes and saved to core data.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func timeLimitButtonAction(_ sender: UIButton) {
        if self.isTimeBound == false {
            let label = "Deselect \"Not time-bound\" to set the lesson's time limit."
            HUD.flash(.label(label), onView: nil, delay: 10.0, completion: nil)
            return
        }
        
        DatePickerDialog().show("Time Limit", doneButtonTitle: "Select", cancelButtonTitle: "Cancel", defaultDate: Date(), minimumDate: nil, maximumDate: nil, datePickerMode: .countDownTimer) { (date) in
            if date != nil {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                
                let time = formatter.string(from: date!).components(separatedBy: ":")
                let hh = self.arfDataManager.intString(time[0])
                let mm = self.arfDataManager.intString(time[1])
                
                let data: [String: Any] = ["minutes": (hh * 60 + mm)]
                let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameId)")
                self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_GAME, predicate: predicate, data: data) { (success) in
                    DispatchQueue.main.async(execute: {
                        if success {
                            let minutes = hh * 60 + mm
                            self.timeLimitTextField.text = "\(minutes) \(minutes > 1 ? "minutes" : "minute")"
                        }
                    })
                }
            }
        }
    }
    
    /// Changes time limit value of game as user clicks
    /// on not time bound button. Update is applied to
    /// deep copy game.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func notTimeBoundButtonAction(_ sender: UIButton) {
        let imageA = ARFConstants.image.GEN_CB_SELECTED
        let imageB = ARFConstants.image.GEN_CB_UNSELECTED
        
        self.isTimeBound = self.isTimeBound ? false : true
        let timeLimitString = "\(self.game.minutes) \(self.game.minutes > 1 ? "minutes" : "minute")"
        
        self.notTimeBoundImage.image = self.isTimeBound ? imageB : imageA
        self.timeLimitTextField.text = self.isTimeBound ? timeLimitString : ""
        
        let data: [String: Any] = ["isTimeBound": self.isTimeBound]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_GAME, predicate: predicate, data: data) { (success) in }
    }
    
    /// Changes availability status of game as user
    /// clicks on always available button. Update is
    /// applied to deep copy game.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func alwaysAvailableButtonAction(_ sender: UIButton) {
        let imageA = ARFConstants.image.GEN_CB_SELECTED
        let imageB = ARFConstants.image.GEN_CB_UNSELECTED
        let format = ARFConstants.timeFormat.CLIENT
        
        let frDateString = self.arfDataManager.string(fromDate: self.game.start ?? Date(), format: format)
        let toDateString = self.arfDataManager.string(fromDate: self.game.end ?? Date(), format: format)
        
        self.isAlwaysAvailable = self.isAlwaysAvailable ? false : true
        self.alwaysAvailableImage.image = self.isAlwaysAvailable ? imageA : imageB
        self.frTextField.text = self.isAlwaysAvailable ? "" : frDateString
        self.toTextField.text = self.isAlwaysAvailable ? "" : toDateString
        
        let data: [String: Any] = ["isNoExpiration": self.isAlwaysAvailable]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_GAME, predicate: predicate, data: data) { (success) in }
    }
    
    /// Presents Date Picker Dialog where user can set
    /// start date for the game. Selected date will be
    /// saved to core data.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func frButtonAction(_ sender: UIButton) {
        if self.isAlwaysAvailable {
            let label = "Deselect \"Always available\" to set the lesson's start date."
            HUD.flash(.label(label), onView: nil, delay: 10.0, completion: nil)
            return
        }
        
        DatePickerDialog().show("Start Date", doneButtonTitle: "Select", cancelButtonTitle: "Cancel", defaultDate: Date(), minimumDate: nil, maximumDate: nil, datePickerMode: .dateAndTime) { (date) in
            if date != nil {
                let formatter = DateFormatter()
                formatter.dateFormat = ARFConstants.timeFormat.CLIENT
                let dateString = formatter.string(from: date!)
                
                let data: [String: Any] = ["start": date!]
                let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameId)")
                self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_GAME, predicate: predicate, data: data) { (success) in
                    DispatchQueue.main.async(execute: { if success { self.frTextField.text = dateString } })
                }
            }
        }
    }
    
    /// Presents Date Picker Dialog where user can set
    /// end date for the game. Selected date will be
    /// saved to core data.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func toButtonAction(_ sender: UIButton) {
        if self.isAlwaysAvailable {
            let label = "Deselect \"Always available\" to set the lesson's end date."
            HUD.flash(.label(label), onView: nil, delay: 10.0, completion: nil)
            return
        }
        
        DatePickerDialog().show("End Date", doneButtonTitle: "Select", cancelButtonTitle: "Cancel", defaultDate: Date(), minimumDate: nil, maximumDate: nil, datePickerMode: .dateAndTime) { (date) in
            if date != nil {
                let formatter = DateFormatter()
                formatter.dateFormat = ARFConstants.timeFormat.CLIENT
                let dateString = formatter.string(from: date!)
                
                let data: [String: Any] = ["end": date!]
                let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameId)")
                self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_GAME, predicate: predicate, data: data) { (success) in
                    DispatchQueue.main.async(execute: { if success { self.toTextField.text = dateString } })
                }
            }
        }
    }
    
    /// Asks user if he really wants to cancel creating
    /// or updating a game. If yes, goes back to the
    /// previous view; otherwise, stays on the current
    /// view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        let action = self.isCreation ? "creating" : "updating"
        let message = "Are you sure you want to cancel \(action) this lesson?"
        let title = "Cancel Operation"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let posAction = UIAlertAction(title: "Yes", style: .default) { (Alert) -> Void in
            DispatchQueue.main.async(execute: { self.dismiss(animated: true, completion: nil) })
        }
        
        let negAction = UIAlertAction(title: "No", style: .cancel) { (Alert) -> Void in
            DispatchQueue.main.async(execute: { alert.dismiss(animated: true, completion: nil) })
        }
        
        alert.addAction(posAction)
        alert.addAction(negAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /// This method does the following: [1] Checks if deep
    /// copy object contains empty required attibutes. If
    /// it does, it notifies the user about the issue;
    /// otherwise, it continues to [2]; [2] Assembles body
    /// for server request; [3] If assembled body is not
    /// nil, it requests for creating or updating of game
    /// with the assembled body as the primary parameter;
    /// [5] Notifies user on the result of request and goes
    /// back to previous view controller if request has
    /// succeeded; otherwise, it stays on the current view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func processButtonAction(_ sender: UIButton) {
        let title = self.isCreation ? "Create Lesson" : "Update Lesson"
        let neKeys = ["name", "discussion", "clueIds", "treasureId", "totalPoints", "isTimeBound", "minutes", "isNoExpiration", "isSecure", "startingClueId", "startingClueName", "owner"]
        let entity = ARFConstants.entity.DEEP_COPY_GAME
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameId)")
        
        if self.game.isNoExpiration == 0 {
            let minutes: Double = self.game.isTimeBound == 1 ? Double(self.game.minutes) * 60.0 : 0.0
            let frDate = self.game.start ?? Date()
            let toDate = self.game.end ?? Date()
            let difference = toDate.timeIntervalSince(frDate)
            
            if difference <= (minutes + 300) {
                DispatchQueue.main.async {
                    let message = "Dates in schedule must have at least 5 minutes difference plus the time limit (if applicable)."
                    HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in })
                }
                
                return
            }
        }
        
        if self.game.treasureName == nil || self.game.treasureName == "" {
            DispatchQueue.main.async {
                let subtitle = "Please select an asset to continue."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
            }
            
            return
        }
        
        if self.game.clueIds == nil || self.game.clueIds == "" {
            DispatchQueue.main.async {
                let subtitle = "Please select at least one question to continue ."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
            }
            
            return
        }
        
        if self.game.startingClueName == "" {
            DispatchQueue.main.async {
                let subtitle = "Please select a starting question from the list."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
            }
            
            return
        }
        
        if self.arfDataManager.doesEntity(entity, filteredBy: predicate, containsEmptyValueForRequiredKeys: neKeys) {
            DispatchQueue.main.async {
                let subtitle = "Required fields cannot be empty. Kindly fill them in to continue."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                    self.checkRequiredFields()
                })
            }
            
            return
        }
        
        let rfKeys = ["name", "discussion", "clueIds", "treasureId", "totalPoints", "isTimeBound", "minutes", "isNoExpiration", "start", "end", "isSecure", "securityCode", "encryptedSecurityCode", "startingClueId", "startingClueName", "owner"]
        let body = self.arfDataManager.assemblePostData(fromEntity: entity, filteredBy: predicate, requiredKeys: rfKeys)
        
        if body != nil {
            HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))

            if self.isCreation {
                self.arfDataManager.requestCreateGame(withBody: body!, completion: { (result) in
                    let status = result!["status"] as! Int

                    if status == 0 {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = result!["message"] as! String
                            HUD.flash(.labeledSuccess(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                                self.dismiss(animated: true, completion: { self.delegate?.requestUpdateView() })
                            })
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
                self.arfDataManager.requestUpdateGame(withId: "\(self.gameId)", body: body!, completion: { (result) in
                    let status = result!["status"] as! Int

                    if status == 0 {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = result!["message"] as! String
                            HUD.flash(.labeledSuccess(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                                self.dismiss(animated: true, completion: { self.delegate?.requestUpdateView() })
                            })
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
        }
        else {
            DispatchQueue.main.async {
                let subtitle = ARFConstants.message.DEFAULT_ERROR
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
            }
        }
    }
    
    // MARK: - Empty Placeholder View
    
    /// Shows or hides empty place holder view as user
    /// requests for clue list.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        self.emptyPlaceholderView.isHidden = !show
        self.cluesTableView.isHidden = show
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sectionCount = fetchedResultsController.sections?.count else { return 0 }
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionData = fetchedResultsController.sections?[section] else { return 0 }
        self.shouldShowEmptyPlaceholderView((sectionData.numberOfObjects > 0) ? false : true)
        return sectionData.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.GAME_CLUE, for: indexPath) as! ARFGCGameClueTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ARFGCGameClueTableViewCell, atIndexPath indexPath: IndexPath) {
        let clueObject = fetchedResultsController.object(at: indexPath) as! DeepCopyGameClue
        let type1Image = ARFConstants.image.GCV_CLUE_TYPE_ID
        let type2Image = ARFConstants.image.GCV_CLUE_TYPE_MC
        let type3Image = ARFConstants.image.GCV_CLUE_TYPE_TF
        
        cell.clueImage.image = ARFConstants.image.GCV_CLUE
        cell.clueLabel.text = clueObject.clue!
        cell.clueRiddleLabel.text = clueObject.riddle!
        cell.clueActPointsLabel.text = "\(clueObject.points)"
        cell.cluePointsLabel.text = clueObject.points > 1 ? "Points" : "Point"
        cell.clueTypeImage.image = clueObject.type == 1 ? type1Image : clueObject.type == 2 ? type2Image : type3Image
        
        let selected = clueObject.id == self.game.startingClueId ? true : false
        cell.backgroundColor = selected ? .lightGray : .white
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let clueObject = fetchedResultsController.object(at: indexPath) as! DeepCopyGameClue
        let data: [String: Any] = ["startingClueId": clueObject.id, "startingClueName": clueObject.riddle!]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_GAME, predicate: predicate, data: data) { (success) in
            DispatchQueue.main.async(execute: { self.renderData() })
        }
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.DEEP_COPY_GAME_CLUE)
        fetchRequest.fetchBatchSize = 20
        
        let predicate = self.arfDataManager.predicate(forKeyPath: "gameId", exactValue: "\(self.gameId)")
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "dateUpdated", ascending: true)
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
        self.cluesTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            self.cluesTableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.cluesTableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.cluesTableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.cluesTableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath {
                if let cell = self.cluesTableView.cellForRow(at: indexPath) {
                    self.configureCell(cell as! ARFGCGameClueTableViewCell, atIndexPath: indexPath)
                }
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.cluesTableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.cluesTableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.cluesTableView.endUpdates()
    }
    
    func reloadFetchedResultsController() {
        self._fetchedResultsController = nil
        self.cluesTableView.reloadData()
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        /// Limit acceptable number of characters to 255
        if textField != self.nameTextField && newText.count > 255 { return false }

        /// Save to core data
        let dataA: [String: Any] = ["name": newText]
        let dataB: [String: Any] = ["securityCode": newText, "encryptedSecurityCode": newText.md5(), "isSecure": newText.count > 0 ? 1 : 0]
        let dataC: [String: Any] = textField == self.nameTextField ? dataA : dataB
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_GAME, predicate: predicate, data: dataC) { (success) in }
        
        return true
    }
    
    // MARK: - Text View Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        let data: [String: Any] = ["discussion": textView.text]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.gameId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_GAME, predicate: predicate, data: data) { (success) in }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars <= 5000000
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_GAME_TREASURE_SELECTION_VIEW {
            guard let data = sender as? [String: Any], let gameId = data["gameId"] as? Int64, let treasureId = data["treasureId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameTreasureSelectionView = segue.destination as! ARFGCGameTreasureSelectionViewController
            gameTreasureSelectionView.gameId = gameId
            gameTreasureSelectionView.isCreation = self.isCreation
            gameTreasureSelectionView.selectedTreasureId = treasureId
            gameTreasureSelectionView.delegate = self
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_GAME_CLUE_SELECTION_VIEW {
            guard let data = sender as? [String: Any], let gameId = data["gameId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameClueSelectionView = segue.destination as! ARFGCGameClueSelectionViewController
            gameClueSelectionView.gameId = gameId
            gameClueSelectionView.isCreation = self.isCreation
            gameClueSelectionView.selectedClues = self.selectedClues
            gameClueSelectionView.delegate = self
        }
        
    }
    
    // MARK: - ARFGCGameTreasureSelectionViewControllerDelegate
    
    func requestRerenderDataForGameTreasureUpdate() {
        DispatchQueue.main.async(execute: {
            self.renderData()
        })
    }
    
    // MARK: - ARFGCGameClueSelectionViewControllerDelegate
    
    func requestRerenderDataForGameCluesUpdate() {
        DispatchQueue.main.async(execute: {
            self.renderData()
        })
    }

}
