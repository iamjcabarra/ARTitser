//
//  ARFGACourseCreationViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 30/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import PKHUD

protocol ARFGACourseCreationViewControllerDelegate: class {
    func requestUpdateView()
}

class ARFGACourseCreationViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var courseCodeLabel: UILabel!
    @IBOutlet var courseTitleLabel: UILabel!
    @IBOutlet var courseDescriptionLabel: UILabel!
    @IBOutlet var courseUnitLabel: UILabel!
    @IBOutlet var characterCounterLabel: UILabel!
    @IBOutlet var courseCodeTextField: UITextField!
    @IBOutlet var courseTitleTextField: UITextField!
    @IBOutlet var courseDescriptionTextField: UITextView!
    @IBOutlet var courseUnitTextField: UITextField!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var processButton: UIButton!
    
    weak var delegate: ARFGACourseCreationViewControllerDelegate?

    var course: DeepCopyCourse!
    var isCreation = false
    
    fileprivate var courseId: Int64 = 0
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = self.isCreation ? "Create Course" : "Update Course"
        
        /// Configure background color
        let backgroundColor = self.isCreation ? ARFConstants.color.GEN_CREATE_ACTION : ARFConstants.color.GEN_UPDATE_ACTION
        self.navigationBar.barTintColor = backgroundColor
        self.bottomView.backgroundColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Configure text view
        self.courseDescriptionTextField.layer.borderWidth = 0.5
        self.courseDescriptionTextField.layer.borderColor = UIColor.lightGray.cgColor
        self.courseDescriptionTextField.layer.cornerRadius = 6
        
        /// Set delegate for text fields
        self.courseCodeTextField.delegate = self
        self.courseTitleTextField.delegate = self
        self.courseDescriptionTextField.delegate = self
        self.courseUnitTextField.delegate = self
        
        /// Configure buttons
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        self.processButton.addTarget(self, action: #selector(self.processButtonAction(_:)), for: .touchUpInside)
        
        /// Render course details
        self.renderData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Data Rendering
    
    /// Binds data with controller's view ui objects.
    fileprivate func renderData() {
        if self.course != nil {
            self.courseCodeTextField.text = self.course.code ?? ""
            self.courseTitleTextField.text = self.course.title ?? ""
            self.courseDescriptionTextField.text = self.course.courseDescription ?? ""
            self.courseUnitTextField.text = "\(self.course.unit)"
            let count = 255 - self.courseDescriptionTextField.text.count
            self.characterCounterLabel.text = "\(count) characters left"
            self.courseId = self.course.id
        }
    }
    
    // MARK: - Text Field Key
    
    /// Assigns key for text field which will be used
    /// for updating deep copy course object in core
    /// data.
    ///
    /// - parameter textField: A UITextField
    fileprivate func key(forTextField textField: UITextField) -> String {
        var key = "code"
        
        if textField == self.courseCodeTextField { key = "code" }
        else if textField == self.courseTitleTextField { key = "title" }
        else if textField == self.courseDescriptionTextField  { key = "courseDescription" }
        else if textField == self.courseUnitTextField { key = "unit" }
        
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
        
        self.courseCodeTextField.backgroundColor = self.courseCodeTextField.text == "" ? negColor : posColor
        self.courseTitleTextField.backgroundColor = self.courseTitleTextField.text == "" ? negColor : posColor
        self.courseDescriptionTextField.backgroundColor = self.courseDescriptionTextField.text == "" ? negColor : posColor
        self.courseUnitTextField.backgroundColor = self.courseUnitTextField.text == "" ? negColor : posColor
    }
    
    // MARK: - Button Event Handlers
    
    /// Asks user if he really wants to cancel creating
    /// or updating a course. If yes, goes back to the
    /// previous view; otherwise, stays on the current
    /// view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        let action = self.isCreation ? "creating" : "updating"
        let message = "Are you sure you want to cancel \(action) this course?"
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
    /// nil, it requests for creating or updating of course
    /// with the assembled body as the primary parameter;
    /// [5] Notifies user on the result of request and goes
    /// back to previous view controller if request has
    /// succeeded; otherwise, it stays on the current view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func processButtonAction(_ sender: UIButton) {
        let title = self.isCreation ? "Create Course" : "Update Course"
        let neKeys = ["code", "title", "courseDescription", "unit"]
        let entity = ARFConstants.entity.DEEP_COPY_COURSE
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.courseId)")
        
        if self.arfDataManager.doesEntity(entity, filteredBy: predicate, containsEmptyValueForRequiredKeys: neKeys) {
            DispatchQueue.main.async {
                let subtitle = "Required fields cannot be empty. Kindly fill them in to continue."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                    self.checkRequiredFields()
                })
            }
            
            return
        }
        
        let rfKeys = ["code", "title", "courseDescription", "unit", "owner"]
        let body = self.arfDataManager.assemblePostData(fromEntity: entity, filteredBy: predicate, requiredKeys: rfKeys)
        
        if body != nil {
            HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
            
            if self.isCreation {
                self.arfDataManager.requestCreateCourse(withBody: body!, completion: { (result) in
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
                self.arfDataManager.requestUpdateCourse(withId: "\(self.courseId)", body: body!, completion: { (result) in
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
    
    // MARK: - Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        /// Limit acceptable number of characters to 255
        if newText.count > 255 { return false }
        
        /// Accept only numeric data for unit
        if (textField == self.courseUnitTextField) {
            let numberSet = CharacterSet.decimalDigits
            if (string as NSString).rangeOfCharacter(from: numberSet.inverted).location != NSNotFound { return false }
            if newText.count > 2 { return false }
        }
        
        /// Update core data for changes
        let key = self.key(forTextField: textField)
        let data: [String: Any] = [key: textField == self.courseUnitTextField ? self.arfDataManager.intString(newText) : newText]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.courseId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_COURSE, predicate: predicate, data: data) { (success) in }
        
        return true
    }
    
    // MARK: - Text View Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        let data: [String: Any] = ["courseDescription": textView.text]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.courseId)")
        
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_COURSE, predicate: predicate, data: data) { (success) in
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
    
}
