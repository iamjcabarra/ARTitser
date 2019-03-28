//
//  ARFGAUserCreationViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 21/11/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import PKHUD
import DatePickerDialog
import SDWebImage

protocol ARFGAUserCreationViewControllerDelegate: class {
    func requestUpdateView()
}

class ARFGAUserCreationViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, ARFGAUserTypePopoverDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var imageBackgroundView: UIView!
    @IBOutlet var imageActionView: UIView!
    @IBOutlet var userImage: UIImageView!
    @IBOutlet var bottomView: UIView!
    
    @IBOutlet var userTypeLabel: UILabel!
    @IBOutlet var firstNameLabel: UILabel!
    @IBOutlet var middleNameLabel: UILabel!
    @IBOutlet var lastNameLabel: UILabel!
    @IBOutlet var genderLabel: UILabel!
    @IBOutlet var birthdateLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var mobileLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var passwordLabel: UILabel!
    @IBOutlet var confirmPasswordLabel: UILabel!
    
    @IBOutlet var userTypeTextField: UITextField!
    @IBOutlet var firstNameTextField: UITextField!
    @IBOutlet var middleNameTextField: UITextField!
    @IBOutlet var lastNameTextField: UITextField!
    @IBOutlet var birthdateTextField: UITextField!
    @IBOutlet var addressTextField: UITextField!
    @IBOutlet var mobileTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var confirmPasswordTextField: UITextField!
    
    @IBOutlet var takePhotoButton: UIButton!
    @IBOutlet var importPhotoButton: UIButton!
    @IBOutlet var userTypeButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var processButton: UIButton!
    @IBOutlet var genderSegmentedControl: UISegmentedControl!
    @IBOutlet var calendarButton: UIButton!
    @IBOutlet var showPasswordButton: UIButton!
    @IBOutlet var showConfirmPasswordButton: UIButton!
    
    weak var delegate: ARFGAUserCreationViewControllerDelegate?
    
    var user: DeepCopyUser!
    var isCreation = false
    var isRegistration = false
    
    fileprivate var userId: Int64 = 0
    fileprivate var showPassword = false
    fileprivate var showConfirmPassword = false
    fileprivate var userImageData: Data? = nil
    fileprivate var userTypePopover: ARFGAUserTypePopover!

    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = self.isRegistration ? "Register" : self.isCreation ? "Create User" : "Update User"
        
        /// Configure background color
        let backgroundColor = self.isCreation ? ARFConstants.color.GEN_CREATE_ACTION : ARFConstants.color.GEN_UPDATE_ACTION
        self.navigationBar.barTintColor = backgroundColor
        self.bottomView.backgroundColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Set delegates for text fields
        self.firstNameTextField.delegate = self
        self.middleNameTextField.delegate = self
        self.lastNameTextField.delegate = self
        self.addressTextField.delegate = self
        self.mobileTextField.delegate = self
        self.emailTextField.delegate = self
        self.usernameTextField.delegate = self
        self.passwordTextField.delegate = self
        self.confirmPasswordTextField.delegate = self
        
        /// Secure or unsecure password
        self.showPasswordButtonAction(nil)
        self.showConfirmPasswordButtonAction(nil)
        
        /// Configure listeners for buttons
        self.importPhotoButton.addTarget(self, action: #selector(self.importButtonAction(_:)), for: .touchUpInside)
        self.takePhotoButton.addTarget(self, action: #selector(self.takePhotoButtonAction(_:)), for: .touchUpInside)
        self.userTypeButton.addTarget(self, action: #selector(self.userTypeButtonAction(_:)), for: .touchUpInside)
        self.genderSegmentedControl.addTarget(self, action: #selector(self.genderSegmentedControlAction(_:)), for: .valueChanged)
        self.calendarButton.addTarget(self, action: #selector(self.calendarButtonAction(_:)), for: .touchUpInside)
        self.showPasswordButton.addTarget(self, action: #selector(self.showPasswordButtonAction(_:)), for: .touchUpInside)
        self.showConfirmPasswordButton.addTarget(self, action: #selector(self.showConfirmPasswordButtonAction(_:)), for: .touchUpInside)
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)) , for: .touchUpInside)
        self.processButton.addTarget(self, action: #selector(self.processButtonAction(_:)), for: .touchUpInside)
        
        /// Render user details
        self.renderData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Data Rendering
    
    /// Binds data with controller's view ui objects.
    fileprivate func renderData() {
        if self.user != nil {
            self.userTypeTextField.text = self.user.type == 0 ? "Administrator" : self.user.type == 1 ? "Teacher" : "Student"
            self.firstNameTextField.text = self.user.firstName ?? ""
            self.middleNameTextField.text = self.user.middleName ?? ""
            self.lastNameTextField.text = self.user.lastName ?? ""
            self.genderSegmentedControl.selectedSegmentIndex = self.user.gender == 0 ? 0 : 1
            self.birthdateTextField.text = self.user.birthdate ?? ""
            self.addressTextField.text = self.user.address ?? ""
            self.mobileTextField.text = self.user.mobile ?? ""
            self.emailTextField.text = self.user.email ?? ""
            self.usernameTextField.text = self.user.username ?? ""
            self.passwordTextField.text = self.user.password ?? ""
            self.confirmPasswordTextField.text = self.user.confirmPassword ?? ""

            self.userImage.sd_setImage(with: URL(string: self.user.imageUrl ?? ""), completed: { (image, error, type, url) in
                self.userImage.image = image != nil ? image! : ARFConstants.image.GEN_UNKNOWN_USER
                self.userImageData = image != nil ? image!.jpegRepresentationData : nil
            })
            
            self.userId = self.user.id
        }
    }
    
    // MARK: - Text Field Key
    
    /// Assigns key for text field which will be used
    /// for updating deep copy user object in core
    /// data.
    ///
    /// - parameter textField: A UITextField
    fileprivate func key(forTextField textField: UITextField) -> String {
        var key = "type"
        
        if textField == self.userTypeTextField { key = "type" }
        else if textField == self.firstNameTextField { key = "firstName" }
        else if textField == self.middleNameTextField  { key = "middleName" }
        else if textField == self.lastNameTextField { key = "lastName" }
        else if textField == self.birthdateTextField { key = "birthdate" }
        else if textField == self.addressTextField { key = "address" }
        else if textField == self.mobileTextField { key = "mobile" }
        else if textField == self.emailTextField { key = "email" }
        else if textField == self.usernameTextField { key = "username" }
        else if textField == self.passwordTextField { key = "password" }
        else if textField == self.confirmPasswordTextField { key = "confirmPassword" }
        
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
        
        self.userTypeTextField.backgroundColor = self.userTypeTextField.text == "" ? negColor : posColor
        self.firstNameTextField.backgroundColor = self.firstNameTextField.text == "" ? negColor : posColor
        self.lastNameTextField.backgroundColor = self.lastNameTextField.text == "" ? negColor : posColor
        self.usernameTextField.backgroundColor = self.usernameTextField.text == "" ? negColor : posColor
        self.passwordTextField.backgroundColor = self.passwordTextField.text == "" ? negColor : posColor
    }
    
    // MARK: - Button Event Handlers
    
    /// Presents the Photo Library where user can
    /// import a photo and use it as the user's photo.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func importButtonAction(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    /// Presents the Camera where user can take a photo
    /// and use it as the user's photo.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func takePhotoButtonAction(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    /// Presents a popover where user can select the
    /// type of the user he is being created or updated.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func userTypeButtonAction(_ sender: UIButton) {
        self.userTypePopover = ARFGAUserTypePopover(nibName: "ARFGAUserTypePopover", bundle: nil)
        self.userTypePopover.delegate = self
        self.userTypePopover.isRegistration = self.isRegistration
        self.userTypePopover.modalPresentationStyle = .popover
        self.userTypePopover.preferredContentSize = CGSize(width: 160.0, height: 132.0)
        self.userTypePopover.popoverPresentationController?.permittedArrowDirections = .right
        self.userTypePopover.popoverPresentationController?.sourceView = sender
        self.userTypePopover.popoverPresentationController?.sourceRect = sender.bounds
        self.userTypePopover.popoverPresentationController?.delegate = self
        self.present(self.userTypePopover, animated: true, completion: nil)
    }
    
    /// Asks user if he really wants to cancel creating
    /// or updating a user. If yes, goes back to the
    /// previous view; otherwise, stays on the current
    /// view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        let action = self.isCreation ? "creating" : "updating"
        let message = self.isRegistration ? "Are you sure you want to cancel your registration?" : "Are you sure you want to cancel \(action) this user?"
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
    /// nil, it requests for creating or updating of user
    /// with the assembled body as the primary parameter;
    /// [5] Notifies user on the result of request and goes
    /// back to previous view controller if request has
    /// succeeded; otherwise, it stays on the current view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func processButtonAction(_ sender: UIButton) {
        let title = self.isRegistration ? "Register User" : self.isCreation ? "Create User" : "Update User"
        
        /// Validate email
        if let email = self.emailTextField.text, email.count > 0 {
            if self.isValidEmail(email) == false {
                DispatchQueue.main.async {
                    let subtitle = "The email address that you have entered is invalid."
                    HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                        self.emailTextField.becomeFirstResponder()
                    })
                }
                
                return
            }
        }
        
        /// Validate username
        if let username = self.usernameTextField.text, username.count > 0 {
            if self.isValidUsername(username) == false {
                DispatchQueue.main.async {
                    let subtitle = "The username that you have entered is invalid."
                    HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                        let label = "Username Requirements: 1) No special characters; 2) Only letters, underscores and numbers allowed; and, 3) Length should be 18 characters maximum and 5 characters minimum."
                        HUD.flash(.label(label), onView: nil, delay: 10.0, completion: { (success) in
                            self.usernameTextField.becomeFirstResponder()
                        })
                    })
                }
                
                return
            }
        }
        
        /// Validate password
        if let password = self.passwordTextField.text, password.count > 0 {
            if self.isValidPassword(password) == false {
                DispatchQueue.main.async {
                    let subtitle = "The password that you have entered is invalid."
                    HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                        let label = "Password Requirements: 1) At least 1 uppercase letter; 2) At least 1 lowercase letter; 3) At least 1 digit; and 4) 8 characters in total."
                        HUD.flash(.label(label), onView: nil, delay: 10.0, completion: { (success) in
                            self.passwordTextField.becomeFirstResponder()
                        })
                    })
                }
                
                return
            }
        }
        
        /// Check if passwords match
        if self.doPasswordsMatch() == false {
            DispatchQueue.main.async {
                let subtitle = "Passwords do not match."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                    self.passwordTextField.becomeFirstResponder()
                })
            }
            
            return
        }
        
        let neKeys = ["lastName", "firstName", "gender", "type", "username", "password"]
        let entity = ARFConstants.entity.DEEP_COPY_USER
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.userId)")
        
        /// Check for empty required fields
        if self.arfDataManager.doesEntity(entity, filteredBy: predicate, containsEmptyValueForRequiredKeys: neKeys) {
            DispatchQueue.main.async {
                let subtitle = "Required fields cannot be empty. Kindly fill them in to continue."
                HUD.flash(.labeledError(title: title, subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in
                    self.checkRequiredFields()
                })
            }
            
            return
        }

        let rfKeys = ["lastName", "firstName", "middleName", "gender", "birthdate", "address", "mobile", "email", "type", "username", "encryptedUsername", "password", "encryptedPassword", "owner", "isForApproval"]
        let body = self.arfDataManager.assemblePostData(fromEntity: entity, filteredBy: predicate, requiredKeys: rfKeys)

        if body != nil {
            HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
            if self.isCreation {
                self.arfDataManager.requestCreateUser(withBody: body!, imageKey: "imageUrl", andImageData: self.userImageData, completion: { (result) in
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
                self.arfDataManager.requestUpdateUser(withId: "\(self.userId)", body: body!, imageKey: "imageUrl", andImageData: self.userImageData, completion: { (result) in
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
    
    /// Changes gender as user switches segemted control.
    ///
    /// - parameter sender: A UISegmentedControl
    @objc fileprivate func genderSegmentedControlAction(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        let data: [String: Any] = ["gender": index]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.userId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_USER, predicate: predicate, data: data) { (success) in }
    }
    
    /// Presents the Date Picker Diaglog as user clicks
    /// on calendar button. It also updates the text of
    /// for birthday text field.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func calendarButtonAction(_ sender: UIButton) {
        DatePickerDialog().show("Birthdate", doneButtonTitle: "Select", cancelButtonTitle: "Cancel", defaultDate: Date(), minimumDate: nil, maximumDate: nil, datePickerMode: .date) { (date) in
            if date != nil {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateString = formatter.string(from: date!)
                
                let data: [String: Any] = ["birthdate": dateString]
                let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.userId)")
                self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_USER, predicate: predicate, data: data) { (success) in
                    DispatchQueue.main.async { if success { self.birthdateTextField.text = dateString } }
                }
            }
        }
    }
    
    /// Shows or hides password.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func showPasswordButtonAction(_ sender: UIButton?) {
        let image = self.showPassword ? ARFConstants.image.GEN_HIDE_PASSWORD : ARFConstants.image.GEN_SHOW_PASSWORD
        self.showPasswordButton.setImage(image, for: .normal)
        self.showPasswordButton.setImage(image, for: .highlighted)
        self.showPasswordButton.setImage(image, for: .focused)
        self.passwordTextField.isSecureTextEntry = !self.showPassword
        self.showPassword = !self.showPassword
    }
    
    /// Shows or hides confirm password.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func showConfirmPasswordButtonAction(_ sender: UIButton?) {
        let image = self.showConfirmPassword ? ARFConstants.image.GEN_HIDE_PASSWORD : ARFConstants.image.GEN_SHOW_PASSWORD
        self.showConfirmPasswordButton.setImage(image, for: .normal)
        self.showConfirmPasswordButton.setImage(image, for: .highlighted)
        self.showConfirmPasswordButton.setImage(image, for: .focused)
        self.confirmPasswordTextField.isSecureTextEntry = !self.showConfirmPassword
        self.showConfirmPassword = !self.showConfirmPassword
    }
    
    // MARK: - Validate User's Inputs
    
    /// Validates if entered email address has the correct
    /// format.
    ///
    /// - parameter email: A String identifying email
    fileprivate func isValidEmail(_ email: String?) -> Bool {
        guard email != nil else { return false }
        let regExpression = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", regExpression)
        return predicate.evaluate(with: email)
    }
    
    /// Validates entered username.
    ///
    /// - parameter username: A String identifying the username
    fileprivate func isValidUsername(_ username: String) -> Bool {
        do {
            let regExpression = try NSRegularExpression(pattern: "^[0-9a-zA-Z\\_]{5,18}$", options: .caseInsensitive)
            if regExpression.matches(in: username, options: [], range: NSMakeRange(0, username.count)).count > 0 { return true }
        }
        catch {
            print("ERROR: Can't validate username!")
            return false
        }
        
        return false
    }
    
    /// Validates if entered password is correct or not.
    /// Password must contain: 1) at least one uppercase;
    /// 2) at lease one digit; 3) at leaset one lowercase;
    /// and, 4) 8 characters in total.
    ///
    /// - parameter password: A String identifying password
    fileprivate func isValidPassword(_ password: String?) -> Bool {
        guard password != nil else { return false }
        let regExpression = "(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{8,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regExpression)
        return predicate.evaluate(with: password)
    }
    
    /// Validates if entered passwords are the same.
    fileprivate func doPasswordsMatch() -> Bool {
        let entity = ARFConstants.entity.DEEP_COPY_USER
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.userId)")
        
        guard let object = self.arfDataManager.db.retrieveObject(forEntity: entity, filteredBy: predicate) as? DeepCopyUser else {
            print("ERROR: Can't retrieve deep copy user object!")
            return false
        }
        
        if let ep = object.encryptedPassword, let cp = object.encryptedConfirmPassword { if ep == cp { return true } }
        
        return false
    }
    
    // MARK: - Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        /// Limit acceptable number of characters to 255
        if newText.count > 255 { return false }
        
        /// Update core data for changes
        let key = self.key(forTextField: textField)
        var data: [String: Any] = [key: newText]
        if textField == self.usernameTextField { data["encryptedUsername"] = newText.md5() }
        if textField == self.passwordTextField { data["encryptedPassword"] = newText.md5() }
        if textField == self.confirmPasswordTextField { data["encryptedConfirmPassword"] = newText.md5() }
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.userId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_USER, predicate: predicate, data: data) { (success) in }
        
        return true
    }
    
    // MARK: - Image Picker Controller Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.userImage.image = image
            self.userImage.contentMode = .scaleAspectFill
            self.userImage.layer.cornerRadius = 50
            self.userImage.clipsToBounds = true
            self.userImageData = image.jpegRepresentationData
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Popover Presentation Controller Delegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    // MARK: - ARFGAUserTypePopoverDelegate
    
    func selectedUserType(_ userType: [String : Any]) {
        let userTypeIdentifier = self.arfDataManager.intString(self.arfDataManager.string(userType["identifier"]))
        let data: [String: Any] = ["type": userTypeIdentifier]
        let predicate = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.userId)")
        self.saveChangedData(forEntity: ARFConstants.entity.DEEP_COPY_USER, predicate: predicate, data: data) { (success) in
            DispatchQueue.main.async { if success { self.userTypeTextField.text = self.arfDataManager.string(userType["description"])} }
        }
    }
    
}
