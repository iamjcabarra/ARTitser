//
//  ARFGCTreasureCreationViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 26/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import GooglePlacePicker
import CoreData
import PKHUD

protocol ARFGCTreasureCreationViewControllerDelegate: class {
    func requestUpdateView()
}

class ARFGCTreasureCreationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GMSPlacePickerViewControllerDelegate, UITextFieldDelegate, UITextViewDelegate, ARFGCFileViewControllerDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var imageView: UILabel!
    @IBOutlet var model3dLabel: UILabel!
    @IBOutlet var claimingQuestionLabel: UILabel!
    @IBOutlet var claimingAnswerLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var imageTextField: UITextField!
    @IBOutlet var model3dTextField: UITextField!
    @IBOutlet var locationTextField: UITextField!
    @IBOutlet var claimingAnswerTextField: UITextField!
    @IBOutlet var pointsTextField: UITextField!
    @IBOutlet var descriptionTextField: UITextView!
    @IBOutlet var claimingQuestionTextField: UITextView!
    @IBOutlet var imageButton: UIButton!
    @IBOutlet var model3dButton: UIButton!
    @IBOutlet var locationButton: UIButton!
    @IBOutlet var isCaseSensitiveButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var processButton: UIButton!
    @IBOutlet var isCaseSensitiveImage: UIImageView!
    
    weak var delegate: ARFGCTreasureCreationViewControllerDelegate?
    
    var treasure: DeepCopyTreasure!
    var isCreation = false
    
    fileprivate var treasureId: Int64 = 0
    fileprivate var treasureImageData: Data? = nil
    fileprivate var treasureModel3dData: Data? = nil
    fileprivate var isCaseSensitive = false
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = self.isCreation ? "Create Asset" : "Update Asset"
        
        /// Configure background color
        let backgroundColor = self.isCreation ? ARFConstants.color.GEN_CREATE_ACTION : ARFConstants.color.GEN_UPDATE_ACTION
        self.navigationBar.barTintColor = backgroundColor
        self.bottomView.backgroundColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Configure text views
        self.descriptionTextField.layer.borderWidth = 0.5
        self.descriptionTextField.layer.borderColor = UIColor.lightGray.cgColor
        self.descriptionTextField.layer.cornerRadius = 6
        self.claimingQuestionTextField.layer.borderWidth = 0.5
        self.claimingQuestionTextField.layer.borderColor = UIColor.lightGray.cgColor
        self.claimingQuestionTextField.layer.cornerRadius = 6
        
        /// Set delegate for text fields
        self.nameTextField.delegate = self
        self.locationTextField.delegate = self
        self.claimingAnswerTextField.delegate = self
        self.pointsTextField.delegate = self
        self.descriptionTextField.delegate = self
        self.claimingQuestionTextField.delegate = self
        
        /// Set case sensitive to unselected
        self.isCaseSensitiveImage.image = ARFConstants.image.GEN_CB_UNSELECTED
        
        /// Configure buttons
        self.imageButton.addTarget(self, action: #selector(self.imageButtonAction(_:)), for: .touchUpInside)
        self.model3dButton.addTarget(self, action: #selector(self.model3dButtonAction(_:)), for: .touchUpInside)
        self.isCaseSensitiveButton.addTarget(self, action: #selector(self.isCaseSensitiveButtAction(_:)), for: .touchUpInside)
        self.locationButton.addTarget(self, action: #selector(self.locationButtonAction(_:)), for: .touchUpInside)
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        self.processButton.addTarget(self, action: #selector(self.processButtonAction(_:)), for: .touchUpInside)
        
        /// Render treasure details
        self.renderData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Data Rendering
    
    /// Binds data with controller's view ui objects.
    fileprivate func renderData() {
        if self.treasure != nil {
            self.nameTextField.text = self.treasure.name ?? ""
            self.descriptionTextField.text = self.treasure.treasureDescription ?? ""
            self.imageTextField.text = self.treasure.imageLocalName ?? ""
            self.model3dTextField.text = self.treasure.model3dLocalName ?? ""
            self.locationTextField.text = self.treasure.locationName ?? ""
            self.claimingQuestionTextField.text = self.treasure.claimingQuestion ?? ""
            self.claimingAnswerTextField.text = self.treasure.claimingAnswers ?? ""
            self.pointsTextField.text = "\(self.treasure.points)"
            self.treasureId = self.treasure.id
            
            let imageA = ARFConstants.image.GEN_CB_SELECTED
            let imageB = ARFConstants.image.GEN_CB_UNSELECTED
            self.isCaseSensitiveImage.image = self.treasure.isCaseSensitive == 1 ? imageA : imageB
            self.isCaseSensitive = self.treasure.isCaseSensitive == 1 ? true : false
        }
    }
    
    // MARK: - Text Field Key
    
    /// Assigns key for text field which will be used
    /// for updating deep copy treasure object in core
    /// data.
    ///
    /// - parameter textField: A UITextField
    fileprivate func key(forTextField textField: UITextField) -> String {
        var key = "name"
        
        if textField == self.nameTextField { key = "name" }
        else if textField == self.imageTextField { key = "imageLocalName" }
        else if textField == self.model3dTextField  { key = "model3dLocalName" }
        else if textField == self.locationTextField { key = "locationName" }
        else if textField == self.claimingAnswerTextField { key = "claimingAnswers" }
        else if textField == self.pointsTextField { key = "points" }
        
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

        self.nameTextField.backgroundColor = self.nameTextField.text == "" ? negColor : posColor
        self.descriptionTextField.backgroundColor = self.descriptionTextField.text == "" ? negColor : posColor
        self.imageTextField.backgroundColor = self.imageTextField.text == "" ? negColor : posColor
        self.locationTextField.backgroundColor = self.locationTextField.text == "" ? negColor : posColor
        self.claimingQuestionTextField.backgroundColor = self.claimingQuestionTextField.text == "" ? negColor : posColor
        self.claimingAnswerTextField.backgroundColor = self.claimingAnswerTextField.text == "" ? negColor : posColor
        self.pointsTextField.backgroundColor = self.pointsTextField.text == "" ? negColor : posColor
    }
    
    // MARK: - Button Event Handlers
    
    /// Presents the Photo Library where user can import
    /// a photo and use it as the treasure's photo.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func imageButtonAction(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    /// Presents the file list view where user can select
    /// a 3D model.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func model3dButtonAction(_ sender: UIButton) {
        let data: [String: Any] = ["isCreation": true]
        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_FILE_VIEW, sender: data)
    }
    
    /// Updates core data for the case sensitivity of
    /// treasure's claiming answers as user clicks on
    /// case sensitive button. It also updates the ui.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func isCaseSensitiveButtAction(_ sender: UIButton) {
        let data: [String: Any] = ["isCaseSensitive": self.isCaseSensitive ? 0 : 1]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.treasureId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_TREASURE, predicate: predicate, data: data) { (success) in
            if success {
                DispatchQueue.main.async(execute: {
                    let imageA = ARFConstants.image.GEN_CB_SELECTED
                    let imageB = ARFConstants.image.GEN_CB_UNSELECTED
                    self.isCaseSensitiveImage.image = self.isCaseSensitive ? imageB : imageA
                    self.isCaseSensitive = self.isCaseSensitive ? false : true
                })
            }
        }
    }
    
    /// Presents Google Place Picker View where user can
    /// pick a location from the map as he clicks on the
    /// location button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func locationButtonAction(_ sender: UIButton) {
        var config = GMSPlacePickerConfig(viewport: nil)
        
        if !self.isCreation {
            if self.treasure != nil {
                let center = CLLocationCoordinate2D(latitude: self.treasure.latitude, longitude: self.treasure.longitude)
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
    /// or updating a treasure. If yes, goes back to the
    /// previous view; otherwise, stays on the current
    /// view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        let action = self.isCreation ? "creating" : "updating"
        let message = "Are you sure you want to cancel \(action) this asset?"
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
    /// nil, it requests for creating or updating of treasure
    /// with the assembled body as the primary parameter;
    /// [5] Notifies user on the result of request and goes
    /// back to previous view controller if request has
    /// succeeded; otherwise, it stays on the current view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func processButtonAction(_ sender: UIButton) {
        let title = self.isCreation ? "Create Asset" : "Update Asset"
//        let neKeys = ["name", "treasureDescription", "claimingQuestion", "claimingAnswers", "encryptedClaimingAnswers", "isCaseSensitive", "longitude", "latitude", "locationName", "points", "imageLocalName", "owner"]
        let neKeys = ["name", "treasureDescription", "imageLocalName", "owner"]
        let entity = ARFConstants.entity.DEEP_COPY_TREASURE
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.treasureId)")
        
        if self.arfDataManager.doesEntity(entity, filteredBy: predicate, containsEmptyValueForRequiredKeys: neKeys) {
            DispatchQueue.main.async {
                let subtitle = "Required fields cannot be empty. Kindly fill them in to continue."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                    self.checkRequiredFields()
                })
            }
            
            return
        }
        
//        let rfKeys = ["name", "treasureDescription", "claimingQuestion", "claimingAnswers", "encryptedClaimingAnswers", "isCaseSensitive", "longitude", "latitude", "locationName", "points", "imageLocalName", "model3dLocalName" ,"owner"]
        let rfKeys = ["name", "treasureDescription", "imageLocalName", "model3dLocalName" ,"owner"]
        let body = self.arfDataManager.assemblePostData(fromEntity: entity, filteredBy: predicate, requiredKeys: rfKeys)
        
        if body != nil {
            HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
            
            if self.isCreation {
                self.arfDataManager.requestCreateTreasure(withBody: body!, imageKey: "imageUrl", imageData: self.treasureImageData, model3dKey: "model3dUrl", andModel3dData: self.treasureModel3dData, completion: { (result) in
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
                self.arfDataManager.requestUpdateTreasure(withId: "\(self.treasureId)", body: body!, imageKey: "imageUrl", imageData: self.treasureImageData, model3dKey: "model3dUrl", andModel3dData: self.treasureModel3dData, completion: { (result) in
                    let status = result!["status"] as! Int

                    if status == 0 {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = result!["message"] as! String
                            HUD.flash(.labeledSuccess(title: title, subtitle: subtitle), onView: nil, delay: 5.0, completion: { (success) in
                                self.dismiss(animated: true, completion: { self.delegate?.requestUpdateView() })
                            })
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            HUD.hide()
                            let subtitle = result!["message"] as! String
                            HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 5.0, completion: { (success) in })
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
    
    // MARK: - Image Picker Controller Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        if let imageUrl = info[UIImagePickerControllerImageURL] as? NSURL, let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let data: [String: Any] = ["imageLocalName": imageUrl.lastPathComponent ?? ""]
            let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.treasureId)")
            self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_TREASURE, predicate: predicate, data: data) { (success) in
                if success {
                    DispatchQueue.main.async(execute: {
                        self.imageTextField.text = imageUrl.lastPathComponent ?? ""
                        self.treasureImageData = image.jpegRepresentationData
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            }
        }
    }
    
    // MARK: - Place Picker View Controller Delegate
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        viewController.dismiss(animated: true, completion: nil)
        self.locationTextField.text = place.name
        let data: [String: Any] = ["longitude": place.coordinate.longitude, "latitude": place.coordinate.latitude, "locationName": place.name]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.treasureId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_TREASURE, predicate: predicate, data: data) { (success) in }
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        DispatchQueue.main.async(execute: {
            viewController.dismiss(animated: true, completion: nil)
            let title = self.isCreation ? "Create Asset" : "Update Asset"
            let subtitle = "No location was selected."
            HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
        })
    }
    
    // MARK: - Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
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
            let dataA: [String: Any] = [key: newText]
            let dataB: [String: Any] = [key: newText, "encryptedClaimingAnswers": newText.md5()]
            let dataC: [String: Any] = textField == self.claimingAnswerTextField ? dataB : dataA
            let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.treasureId)")
            self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_TREASURE, predicate: predicate, data: dataC) { (success) in }
        }
        else {
            let key = self.key(forTextField: textField)
            let points = self.arfDataManager.intString(newText)
            let data: [String: Any] = [key: points]
            let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.treasureId)")
            self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_TREASURE, predicate: predicate, data: data) { (success) in }
        }
        
        return true
    }
    
    // MARK: - Text View Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        let dataA: [String: Any] = ["treasureDescription": textView.text]
        let dataB: [String: Any] = ["claimingQuestion": textView.text]
        let dataC: [String: Any] = textView == self.descriptionTextField ? dataA : dataB
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.treasureId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_TREASURE, predicate: predicate, data: dataC) { (success) in }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars <= 255
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_FILE_VIEW {
            guard let data = sender as? [String: Any], let isCreation = data["isCreation"] as? Bool else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let fileView = segue.destination as! ARFGCFileViewController
            fileView.isCreation = isCreation
            fileView.delegate = self
        }
        
    }
    
    // MARK: - ARFGCFileViewControllerDelegate
    
    func selectedFile(withName name: String, andData data: Data) {
        self.model3dTextField.text = name
        self.treasureModel3dData = data
        let data: [String: Any] = ["model3dLocalName": name]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.treasureId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_TREASURE, predicate: predicate, data: data) { (success) in }
    }

}
