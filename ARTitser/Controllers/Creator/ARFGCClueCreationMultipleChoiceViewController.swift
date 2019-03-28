//
//  ARFGCClueCreationMultipleChoiceViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 06/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import GooglePlacePicker
import CoreData
import PKHUD

protocol ARFGCClueCreationMultipleChoiceViewControllerDelegate: class {
    func requestUpdateView()
}

class ARFGCClueCreationMultipleChoiceViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, GMSPlacePickerViewControllerDelegate, UITextFieldDelegate, UITextViewDelegate, UIPopoverPresentationControllerDelegate, ARFGCSetAttemptsPopoverDelegate{
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var riddleLabel: UILabel!
    @IBOutlet var choicesLabel: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var pointsAttemptsLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var clueLabel: UILabel!
    @IBOutlet var riddleTextField: UITextView!
    @IBOutlet var pointsTextField: UITextField!
    @IBOutlet var pointsAttemptsTextField: UITextField!
    @IBOutlet var locationTextField: UITextField!
    @IBOutlet var clueTextField: UITextField!
    @IBOutlet var pointsAttemptsButton: UIButton!
    @IBOutlet var locationButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var processButton: UIButton!
    @IBOutlet var tableView: UITableView!
    
    weak var delegate: ARFGCClueCreationMultipleChoiceViewControllerDelegate?
    
    var clue: DeepCopyClue!
    var isCreation = false
    
    fileprivate var clueId: Int64 = 0
    fileprivate var setAttemptsPopover: ARFGCSetAttemptsPopover!
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = self.isCreation ? "Create Question" : "Update Question"
        
        /// Configure background color
        let backgroundColor = self.isCreation ? ARFConstants.color.GEN_CREATE_ACTION : ARFConstants.color.GEN_UPDATE_ACTION
        self.navigationBar.barTintColor = backgroundColor
        self.bottomView.backgroundColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Configure text view
        self.riddleTextField.layer.borderWidth = 0.5
        self.riddleTextField.layer.borderColor = UIColor.lightGray.cgColor
        self.riddleTextField.layer.cornerRadius = 6
        
        /// Set delegate for text fields
        self.riddleTextField.delegate = self
        self.pointsTextField.delegate = self
        self.clueTextField.delegate = self
        
        /// Configure listeners for buttons
        self.pointsAttemptsButton.addTarget(self, action: #selector(self.pointsOnAttemptsAction(_:)), for: .touchUpInside)
        self.locationButton.addTarget(self, action: #selector(self.locationButtonAction(_:)), for: .touchUpInside)
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)) , for: .touchUpInside)
        self.processButton.addTarget(self, action: #selector(self.processButtonAction(_:)), for: .touchUpInside)
        
        /// Render clue details
        self.renderData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Data Rendering
    
    /// Binds data with controller's view ui objects.
    fileprivate func renderData() {
        if self.clue != nil {
            self.riddleTextField.text = self.clue.riddle ?? ""
            self.pointsTextField.text = "\(self.clue.points)"
            self.pointsAttemptsTextField.text = self.clue.pointsOnAttemptsFormatted ?? ""
            self.locationTextField.text = self.clue.locationName ?? ""
            self.clueTextField.text = self.clue.clue ?? ""
            self.clueId = self.clue.id
        }
    }
    
    // MARK: - Text Field Key
    
    /// Assigns key for text field which will be used
    /// for updating deep copy clue object in core
    /// data.
    ///
    /// - parameter textField: A UITextField
    fileprivate func key(forTextField textField: UITextField) -> String {
        var key = "riddle"
        
        if textField == self.riddleTextField { key = "riddle" }
        else if textField == self.pointsTextField { key = "points" }
        else if textField == self.pointsAttemptsTextField  { key = "pointsOnAttempts" }
        else if textField == self.locationTextField { key = "locationName" }
        else if textField == self.clueTextField { key = "clue" }
        
        return key
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
    
    // MARK: - Retrieving Managed Object
    
    /// Retrieves managed object from the given button in table view.
    ///
    /// - parameters:
    ///     - button: A UIButton
    ///     - inTableView: A UITableView
    fileprivate func managedObject(fromButton button: UIButton, inTableView: UITableView) -> NSManagedObject? {
        let buttonPosition = button.convert(CGPoint.zero, to: inTableView)
        guard let indexPath = inTableView.indexPathForRow(at: buttonPosition) else { return nil }
        let managedObject = self.fetchedResultsController.object(at: indexPath)
        return managedObject
    }
    
    /// Retrieves managed object from the given text field in table view.
    ///
    /// - parameters:
    ///     - textField: A UITextField
    ///     - inTableView: A UITableView
    fileprivate func managedObject(fromTextField textField: UITextField, inTableView: UITableView) -> NSManagedObject? {
        let textFieldPosition = textField.convert(CGPoint.zero, to: inTableView)
        guard let indexPath = inTableView.indexPathForRow(at: textFieldPosition) else { return nil }
        let managedObject = self.fetchedResultsController.object(at: indexPath)
        return managedObject
    }
    
    // MARK: - Check for Required Fields
    
    /// Changes background color of required fields to red
    /// if empty or white if not.
    fileprivate func checkRequiredFields() {
        let posColor = UIColor(hex: "ffffff")
        let negColor = UIColor(hex: "f9e8e8")
        
        self.riddleTextField.backgroundColor = self.riddleTextField.text == "" ? negColor : posColor
        self.pointsTextField.backgroundColor = self.pointsTextField.text == "" ? negColor : posColor
        self.pointsAttemptsTextField.backgroundColor = self.pointsAttemptsTextField.text == "" ? negColor : posColor
        self.locationTextField.backgroundColor = self.locationTextField.text == "" ? negColor : posColor
        self.clueTextField.backgroundColor = self.clueTextField.text == "" ? negColor : posColor
    }
    
    // MARK: - Button Event Handlers
    
    /// Presents a modal popup where user can configure the
    /// distribution of points per attempt.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func pointsOnAttemptsAction(_ sender: UIButton) {
        self.setAttemptsPopover = ARFGCSetAttemptsPopover(nibName: "ARFGCSetAttemptsPopover", bundle: nil)
        self.setAttemptsPopover.delegate = self
        self.setAttemptsPopover.modalPresentationStyle = .popover
        self.setAttemptsPopover.preferredContentSize = CGSize(width: 200.0, height: 340.0)
        self.setAttemptsPopover.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        self.setAttemptsPopover.popoverPresentationController?.sourceView = self.view
        self.setAttemptsPopover.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        self.setAttemptsPopover.popoverPresentationController?.delegate = self
        self.setAttemptsPopover.points = self.arfDataManager.intString(self.pointsTextField.text!)
        self.setAttemptsPopover.prePointsOnAttempts = self.clue.pointsOnAttempts!
        self.present(self.setAttemptsPopover, animated: true, completion: nil)
    }
    
    /// Presents Google Place Picker View where user can
    /// pick a location from the map as he clicks on the
    /// location button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func locationButtonAction(_ sender: UIButton) {
        var config = GMSPlacePickerConfig(viewport: nil)
        
        if !self.isCreation {
            if self.clue != nil {
                let center = CLLocationCoordinate2D(latitude: self.clue.latitude, longitude: self.clue.longitude)
                let northEast = CLLocationCoordinate2D(latitude: center.latitude + 0.001, longitude: center.longitude + 0.001)
                let southWest = CLLocationCoordinate2D(latitude: center.latitude - 0.001, longitude: center.longitude - 0.001)
                let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
                config = GMSPlacePickerConfig(viewport: viewport)
            }
        }
        
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        self.present(placePicker, animated: true, completion: nil)
    }
    
    /// Asks user if he really wants to cancel creating
    /// or updating a clue. If yes, goes back to the
    /// previous view; otherwise, stays on the current
    /// view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        let action = self.isCreation ? "creating" : "updating"
        let message = "Are you sure you want to cancel \(action) this question?"
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
    /// nil, it requests for creating or updating of clue
    /// with the assembled body as the primary parameter;
    /// [5] Notifies user on the result of request and goes
    /// back to previous view controller if request has
    /// succeeded; otherwise, it stays on the current view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func processButtonAction(_ sender: UIButton) {
        let title = self.isCreation ? "Create Question" : "Update Question"
//        let neKeys = ["type", "riddle", "longitude", "latitude", "locationName", "points", "pointsOnAttempts", "clue", "owner", "choices"]
        let neKeys = ["type", "riddle", "points", "pointsOnAttempts", "owner", "choices"]
        let entity = ARFConstants.entity.DEEP_COPY_CLUE
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.clueId)")
        
        if self.arfDataManager.doesEntity(entity, filteredBy: predicate, containsEmptyValueForRequiredKeys: neKeys) {
            DispatchQueue.main.async {
                let subtitle = "Required fields cannot be empty. Kindly fill them in to continue."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                    self.checkRequiredFields()
                })
            }
            
            return
        }
        
        if !self.arfDataManager.isMultipleChoiceValid(forDeepCopyClue: self.clue) {
            DispatchQueue.main.async {
                let label = "Choices cannot be empty. Also, one of them should be set as the correct answer."
                HUD.flash(.label(label), onView: nil, delay: 3.5, completion: nil)
            }
            
            return
        }
        
//        let rfKeys = ["type", "riddle", "longitude", "latitude", "locationName", "points", "pointsOnAttempts", "clue", "owner", "choices"]
        let rfKeys = ["type", "riddle", "points", "pointsOnAttempts", "owner", "choices"]
        let body = self.arfDataManager.assemblePostData(fromEntity: entity, filteredBy: predicate, requiredKeys: rfKeys)
        
        if body != nil {
            HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
            
            if self.isCreation {
                self.arfDataManager.requestCreateClue(withBody: body!, completion: { (result) in
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
                self.arfDataManager.requestUpdateClue(withId: "\(self.clueId)", body: body!, completion: { (result) in
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
    
    /// Fetches the deep copy clue choice object from the
    /// core data and updates the value of its isCorrect
    /// attribute. It makes sure that there is only one
    /// correct answer among the list of choices.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func isCorrectButtonAction(_ sender: UIButton) {
        guard let object = self.managedObject(fromButton: sender, inTableView: self.tableView) as? DeepCopyClueChoice else { return }
        let dataA: [String: Any] = ["isCorrect": 1]
        let predicateA = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(object.id)")
        
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_CLUE_CHOICE, predicate: predicateA, data: dataA) { (success) in
            let dataB: [String: Any] = ["isCorrect": 0]
            let predicateB = self.arfDataManager.predicate(forKeyPath: "id", notValue: "\(object.id)")
            
            self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_CLUE_CHOICE, predicate: predicateB, data: dataB, completion: { (success) in
                self.arfDataManager.assembleChoicesString(forDeepCopyClue: self.clue, completion: { (success) in
                    DispatchQueue.main.async { self.reloadFetchedResultsController() }
                })
            })
        }
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
        let identifier = ARFConstants.cellIdentifier.CLUE_CREATION_MULTIPLE_CHOICE
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ARFGCClueCreationMultipleChoiceTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ARFGCClueCreationMultipleChoiceTableViewCell, atIndexPath indexPath: IndexPath) {
        let choiceObject = fetchedResultsController.object(at: indexPath) as! DeepCopyClueChoice
        cell.choiceStatementTextField.text = choiceObject.choiceStatement!
        cell.choiceStatementTextField.tag = 1
        cell.choiceStatementTextField.delegate = self
        cell.isCorrectImage.image = choiceObject.isCorrect == 1 ? ARFConstants.image.GEN_RB_SELECTED : ARFConstants.image.GEN_RB_UNSELECTED
        cell.isCorrectButton.addTarget(self, action: #selector(self.isCorrectButtonAction(_:)), for: .touchUpInside)
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.DEEP_COPY_CLUE_CHOICE)
        fetchRequest.fetchBatchSize = 20
        
        let predicate = self.arfDataManager.predicate(forKeyPath: "clueId", exactValue: "\(self.clueId)")
        fetchRequest.predicate = predicate
        
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
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.tableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath {
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    self.configureCell(cell as! ARFGCClueCreationMultipleChoiceTableViewCell, atIndexPath: indexPath)
                }
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func reloadFetchedResultsController() {
        self._fetchedResultsController = nil
        self.tableView.reloadData()
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Place Picker View Controller Delegate
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        viewController.dismiss(animated: true, completion: nil)
        let data: [String: Any] = ["longitude": place.coordinate.longitude, "latitude": place.coordinate.latitude, "locationName": place.name]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.clueId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_CLUE, predicate: predicate, data: data) { (success) in
            if success { DispatchQueue.main.async(execute: { self.renderData() }) }
        }
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        DispatchQueue.main.async(execute: {
            viewController.dismiss(animated: true, completion: nil)
            let title = self.isCreation ? "Create Question" : "Update Question"
            let subtitle = "No location was selected."
            HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
        })
    }
    
    // MARK: - Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField.tag != 1 {
            /// Limit acceptable number of characters to 255
            if textField != self.pointsTextField && newText.count > 255 { return false }
            
            /// Limit acceptable number of characters to 5 for points text field
            if textField == self.pointsTextField && newText.count > 5 { return false }
            
            /// Accept only numeric data for points
            if (textField == self.pointsTextField) {
                let numberSet = CharacterSet.decimalDigits
                if (string as NSString).rangeOfCharacter(from: numberSet.inverted).location != NSNotFound { return false }
            }
            
            /// Update core data for changes
            if textField != self.pointsTextField {
                let key = self.key(forTextField: textField)
                let data: [String: Any] = [key: newText]
                let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.clueId)")
                self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_CLUE, predicate: predicate, data: data) { (success) in }
            }
            else {
                let points = self.arfDataManager.intString(newText)
                let poa = "\(points / 1),\(points / 2),\(points / 3),\(points / 4)"
                let formattedPoa = "[1] \(points / 1); [2] \(points / 2), [3] \(points / 3); [4] \(points / 4)"
                let data: [String: Any] = ["points": points, "pointsOnAttempts": poa, "pointsOnAttemptsFormatted": formattedPoa]
                let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.clueId)")
                self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_CLUE, predicate: predicate, data: data) { (success) in
                    if success { DispatchQueue.main.async(execute: { self.renderData() }) }
                }
            }
            
            return true
        }
        else {
            /// Limit acceptable number of characters to 255
            if newText.count > 255 { return false }
            return true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let choiceStatement = textField.text else { return }
        guard let object = self.managedObject(fromTextField: textField, inTableView: self.tableView) as? DeepCopyClueChoice else { return }
        let data: [String: Any] = ["choiceStatement": choiceStatement]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(object.id)")
        
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_CLUE_CHOICE, predicate: predicate, data: data) { (success) in
            self.arfDataManager.assembleChoicesString(forDeepCopyClue: self.clue, completion: { (success) in
                DispatchQueue.main.async { self.reloadFetchedResultsController() }
            })
        }
    }
    
    // MARK: - Text View Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        let data: [String: Any] = ["riddle": textView.text]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.clueId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_CLUE, predicate: predicate, data: data) { (success) in }
    }
    
    // MARK: - Popover Presentation Controller Delegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    // MARK: - ARFGCSetAttemptsPopoverDelegate
    
    func updatedPointsOnAttempt(_ poa: String, poaFormatted: String) {
        let data: [String: Any] = ["pointsOnAttempts": poa, "pointsOnAttemptsFormatted": poaFormatted]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.clueId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_CLUE, predicate: predicate, data: data) { (success) in
            if success { DispatchQueue.main.async(execute: { self.pointsAttemptsTextField.text = poaFormatted }) }
        }
    }
    
}

