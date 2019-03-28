//
//  ARFGAClassCreationViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 07/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import CoreData
import PKHUD
import SDWebImage

protocol ARFGAClassCreationViewControllerDelegate: class {
    func requestUpdateView()
}

class ARFGAClassCreationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate, UITextViewDelegate, ARFGAClassUserSelectionViewControllerDelegate, ARFGAClassCourseSelectionViewControllerDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var emptyPlaceholderView: UIView!
    @IBOutlet var classCodeLabel: UILabel!
    @IBOutlet var classDescriptionLabel: UILabel!
    @IBOutlet var characterCounterLabel: UILabel!
    @IBOutlet var classScheduleLabel: UILabel!
    @IBOutlet var classVenueLabel: UILabel!
    @IBOutlet var classCourseLabel: UILabel!
    @IBOutlet var classPlayersLabel: UILabel!
    @IBOutlet var classCreatorLabel: UILabel!
    @IBOutlet var classCodeTextField: UITextField!
    @IBOutlet var classDescriptionTextField: UITextView!
    @IBOutlet var classScheduleTextField: UITextField!
    @IBOutlet var classVenueTextField: UITextField!
    @IBOutlet var classCourseTextField: UITextField!
    @IBOutlet var classCreatorTextField: UITextField!
    @IBOutlet var classCourseButton: UIButton!
    @IBOutlet var classCreatorButton: UIButton!
    @IBOutlet var classPlayersButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var processButton: UIButton!
    @IBOutlet var classPlayerTableView: UITableView!
    
    weak var delegate: ARFGAClassCreationViewControllerDelegate?
    
    var classId: Int64 = 0
    var isCreation = false
    
    fileprivate var klase: DeepCopyClass!
    fileprivate var selectedUsers: [Int64]? = nil
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = self.isCreation ? "Create Class" : "Update Class"
        
        /// Hide empty place holder by default
        self.shouldShowEmptyPlaceholderView(false)
        
        /// Configure background color
        let backgroundColor = self.isCreation ? ARFConstants.color.GEN_CREATE_ACTION : ARFConstants.color.GEN_UPDATE_ACTION
        self.navigationBar.barTintColor = backgroundColor
        self.bottomView.backgroundColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Configure text view
        self.classDescriptionTextField.layer.borderWidth = 0.5
        self.classDescriptionTextField.layer.borderColor = UIColor.lightGray.cgColor
        self.classDescriptionTextField.layer.cornerRadius = 6
        
        /// Set delegate for text fields
        self.classCodeTextField.delegate = self
        self.classDescriptionTextField.delegate = self
        self.classScheduleTextField.delegate = self
        self.classVenueTextField.delegate = self
        
        /// Configure buttons
        self.classCourseButton.addTarget(self, action: #selector(self.classCourseButtonAction(_:)), for: .touchUpInside)
        self.classCreatorButton.addTarget(self, action: #selector(self.classCreatorButtonAction(_:)), for: .touchUpInside)
        self.classPlayersButton.addTarget(self, action: #selector(self.classPlayersButtonAction(_:)), for: .touchUpInside)
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        self.processButton.addTarget(self, action: #selector(self.processButtonAction(_:)), for: .touchUpInside)

        /// Render class details
        self.renderData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Data Rendering
    
    /// Binds data with controller's view ui objects.
    fileprivate func renderData() {
        let entity = ARFConstants.entity.DEEP_COPY_CLASS
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.classId)")
        
        guard let klase = self.arfDataManager.db.retrieveObject(forEntity: entity, filteredBy: predicate) as? DeepCopyClass else {
            print("ERROR: Can't retrieve deep copy class!")
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        self.klase = klase
        
        self.classCodeTextField.text = self.klase.code ?? ""
        self.classDescriptionTextField.text = self.klase.aClassDescription ?? ""
        self.classScheduleTextField.text = self.klase.schedule ?? ""
        self.classVenueTextField.text = self.klase.venue ?? ""
        
        if let course = self.klase.deepCopyCourse { self.classCourseTextField.text = course.code ?? "" }
        
        if let creator = self.klase.deepCopyCreator {
            let firstName = creator.firstName ?? ""
            let middleName = creator.middleName ?? ""
            let lastName = creator.lastName ?? ""
            let fullName = middleName == "" ? "\(firstName) \(lastName)" : "\(firstName) \(middleName) \(lastName)"
            self.classCreatorTextField.text = fullName
        }
        
        let count = 255 - self.classDescriptionTextField.text.count
        self.characterCounterLabel.text = "\(count) characters left"
        self.reloadFetchedResultsController()
    }
    
    // MARK: - Text Field Key
    
    /// Assigns key for text field which will be used
    /// for updating deep copy class object in core
    /// data.
    ///
    /// - parameter textField: A UITextField
    fileprivate func key(forTextField textField: UITextField) -> String {
        var key = "code"

        if textField == self.classCodeTextField { key = "code" }
        else if textField == self.classScheduleTextField { key = "schedule" }
        else if textField == self.classVenueTextField  { key = "venue" }
        
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
    
    // MARK: - Check for Required Fields
    
    /// Changes background color of required fields to red
    /// if empty or white if not.
    fileprivate func checkRequiredFields() {
        let posColor = UIColor(hex: "ffffff")
        let negColor = UIColor(hex: "f9e8e8")
        
        self.classCodeTextField.backgroundColor = self.classCodeTextField.text == "" ? negColor : posColor
        self.classDescriptionTextField.backgroundColor = self.classDescriptionTextField.text == "" ? negColor : posColor
        self.classScheduleTextField.backgroundColor = self.classScheduleTextField.text == "" ? negColor : posColor
        self.classVenueTextField.backgroundColor = self.classVenueTextField.text == "" ? negColor : posColor
        self.classCourseTextField.backgroundColor = self.classCourseTextField.text == "" ? negColor : posColor
        self.classCreatorTextField.backgroundColor = self.classCreatorTextField.text == "" ? negColor : posColor
    }
    
    // MARK: - Button Event Handlers
    
    /// Presents course selection view as user clicks
    /// on class course button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func classCourseButtonAction(_ sender: UIButton) {
        let data: [String: Any] = ["classId":self.klase.id, "courseId": self.klase.courseId]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GAV_CLASS_COURSE_SELECTION_VIEW, sender: data)
    }
    
    /// Presents creator selection view as user clicks
    /// on class creator button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func classCreatorButtonAction(_ sender: UIButton) {
        self.selectedUsers = [self.klase.creatorId]
        let data: [String: Any] = ["classId":self.klase.id, "isForCreator": true]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GAV_CLASS_USER_SELECTION_VIEW, sender: data)
    }
    
    /// Presents player selection view as user clicks
    /// on class player button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func classPlayersButtonAction(_ sender: UIButton) {
        let playerIds = self.arfDataManager.string(self.klase.playerIds)
        self.selectedUsers = [Int64]()
        let playerList = playerIds.components(separatedBy: ",")
        for p in playerList { self.selectedUsers?.append(self.arfDataManager.intString(p)) }
        let data: [String: Any] = ["classId":self.klase.id, "isForCreator": false]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GAV_CLASS_USER_SELECTION_VIEW, sender: data)
    }
    
    /// Asks user if he really wants to cancel creating
    /// or updating a course. If yes, goes back to the
    /// previous view; otherwise, stays on the current
    /// view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        let action = self.isCreation ? "creating" : "updating"
        let message = "Are you sure you want to cancel \(action) this class?"
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
    /// nil, it requests for creating or updating of class
    /// with the assembled body as the primary parameter;
    /// [5] Notifies user on the result of request and goes
    /// back to previous view controller if request has
    /// succeeded; otherwise, it stays on the current view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func processButtonAction(_ sender: UIButton) {
        let title = self.isCreation ? "Create Class" : "Update Class"
        let neKeys = ["code", "aClassDescription", "schedule", "venue", "courseId", "courseCode", "creatorId", "creatorName", "playerIds"]
        let entity = ARFConstants.entity.DEEP_COPY_CLASS
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.classId)")
        
        if self.klase.creatorName == nil || self.klase.creatorName == "" {
            DispatchQueue.main.async {
                let subtitle = "Please select a creator to continue."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
            }
            
            return
        }
        
        if self.klase.playerIds == nil || self.klase.playerIds == "" {
            DispatchQueue.main.async {
                let subtitle = "Please select at least one player to continue."
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
        
        let rfKeys = ["code", "aClassDescription", "schedule", "venue", "courseId", "creatorId", "playerIds", "owner"]
        let body = self.arfDataManager.assemblePostData(fromEntity: entity, filteredBy: predicate, requiredKeys: rfKeys)
        
        if body != nil {
            HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
            
            if self.isCreation {
                self.arfDataManager.requestCreateClass(withBody: body!, completion: { (result) in
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
                self.arfDataManager.requestUpdateClass(withId: "\(self.classId)", body: body!, completion: { (result) in
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
    /// requests for class list.
    ///
    /// - parameter show: A Bool (true or false)
    fileprivate func shouldShowEmptyPlaceholderView(_ show: Bool) {
        self.emptyPlaceholderView.isHidden = !show
        self.classPlayerTableView.isHidden = show
    }
    
    // MARK: - Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        /// Limit acceptable number of characters to 255
        if newText.count > 255 { return false }
        
        /// Update core data for changes
        let key = self.key(forTextField: textField)
        let data: [String: Any] = [key: newText]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.classId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_CLASS, predicate: predicate, data: data) { (success) in }
        
        return true
    }
    
    // MARK: - Text View Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        let data: [String: Any] = ["aClassDescription": textView.text]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.classId)")
        
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_CLASS, predicate: predicate, data: data) { (success) in
            DispatchQueue.main.async {
                let count = 255 - textView.text.count
                self.characterCounterLabel.text = "\(count) characters left"
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars <= 255
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
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.CLASS_PLAYER, for: indexPath) as! ARFGAClassPlayerTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: ARFGAClassPlayerTableViewCell, atIndexPath indexPath: IndexPath) {
        let playerObject = fetchedResultsController.object(at: indexPath) as! DeepCopyClassPlayer
        let firstName = playerObject.firstName!
        let middleName = playerObject.middleName!
        let lastName = playerObject.lastName!
        let imageUrl = playerObject.imageUrl!
        
        cell.playerNameLabel.text = middleName == "" ? "\(firstName) \(lastName)" : "\(firstName) \(middleName) \(lastName)"
        cell.playerImage.sd_setImage(with: URL(string: imageUrl), completed: { (image, error, type, url) in
            cell.playerImage.image = image != nil ? image! : ARFConstants.image.GEN_UNKNOWN_USER
        })
    }
    
    // MARK: - Fetched Results Controller
    
    fileprivate var _fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let ctx = self.arfDataManager.db.retrieveObjectMainContext()
        
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: ARFConstants.entity.DEEP_COPY_CLASS_PLAYER)
        fetchRequest.fetchBatchSize = 20
        
        let predicate = self.arfDataManager.predicate(forKeyPath: "classId", exactValue: "\(self.classId)")
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "firstName", ascending: true)
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
        self.classPlayerTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            self.classPlayerTableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.classPlayerTableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.classPlayerTableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.classPlayerTableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath {
                if let cell = self.classPlayerTableView.cellForRow(at: indexPath) {
                    self.configureCell(cell as! ARFGAClassPlayerTableViewCell, atIndexPath: indexPath)
                }
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.classPlayerTableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.classPlayerTableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.classPlayerTableView.endUpdates()
    }
    
    func reloadFetchedResultsController() {
        self._fetchedResultsController = nil
        self.classPlayerTableView.reloadData()
        
        do {
            try _fetchedResultsController!.performFetch()
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GAV_CLASS_USER_SELECTION_VIEW {
            guard let data = sender as? [String: Any], let classId = data["classId"] as? Int64, let isForCreator = data["isForCreator"] as? Bool else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let classUserSelectionView = segue.destination as! ARFGAClassUserSelectionViewController
            classUserSelectionView.classId = classId
            classUserSelectionView.isForCreator = isForCreator
            classUserSelectionView.isCreation = self.isCreation
            classUserSelectionView.selectedUsers = self.selectedUsers
            classUserSelectionView.delegate = self
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GAV_CLASS_COURSE_SELECTION_VIEW {
            guard let data = sender as? [String: Any], let classId = data["classId"] as? Int64, let courseId = data["courseId"] as? Int64 else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let classCourseSelectionView = segue.destination as! ARFGAClassCourseSelectionViewController
            classCourseSelectionView.classId = classId
            classCourseSelectionView.isCreation = self.isCreation
            classCourseSelectionView.selectedCourseId = courseId
            classCourseSelectionView.delegate = self
        }
        
    }

    // MARK: - ARFGAClassUserSelectionViewControllerDelegate
    
    func requestRerenderDataForClassUserUpdate() {
        DispatchQueue.main.async(execute: {
            self.renderData()
        })
    }
    
    // MARK: - ARFGAClassCourseSelectionViewControllerDelegate
    
    func requestRerenderDataForClassCourseUpdate() {
        DispatchQueue.main.async(execute: {
            self.renderData()
        })
    }
}
