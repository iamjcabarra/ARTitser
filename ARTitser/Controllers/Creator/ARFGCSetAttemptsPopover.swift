//
//  ARFGCSetAttemptsPopover.swift
//  ARFollow
//
//  Created by Julius Abarra on 13/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import PKHUD

protocol ARFGCSetAttemptsPopoverDelegate: class {
    func updatedPointsOnAttempt(_ poa: String, poaFormatted: String)
}

class ARFGCSetAttemptsPopover: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var attemptsLabel: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var attempt1Label: UILabel!
    @IBOutlet var attempt2Label: UILabel!
    @IBOutlet var attempt3Label: UILabel!
    @IBOutlet var attempt4Label: UILabel!
    @IBOutlet var totalPointsLabel: UILabel!
    @IBOutlet var actTotalPointsLabel: UILabel!
    @IBOutlet var attempt1TextField: UITextField!
    @IBOutlet var attempt2TextField: UITextField!
    @IBOutlet var attempt3TextField: UITextField!
    @IBOutlet var attempt4TextField: UITextField!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var saveButton: UIButton!
    
    weak var delegate: ARFGCSetAttemptsPopoverDelegate?
    var points: Int64 = 0
    var prePointsOnAttempts = ""
    
    fileprivate var poa = ""
    fileprivate var formattedPoa = ""

    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Set total allowable points
        self.actTotalPointsLabel.text = "\(Int(self.points))"
        
        /// Set texts for text fields
        self.renderData()
        
        /// Configure text fields
        self.attempt1TextField.delegate = self
        self.attempt2TextField.delegate = self
        self.attempt3TextField.delegate = self
        self.attempt4TextField.delegate = self

        /// Configure buttons
        self.resetButton.addTarget(self, action: #selector(self.resetButtonAction(_:)), for: .touchUpInside)
        self.saveButton.addTarget(self, action: #selector(self.saveButtonAction(_:)), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Data Rendering
    
    /// Binds data with controller's view ui objects.
    fileprivate func renderData() {
        let pointList = self.prePointsOnAttempts.components(separatedBy: ",")
        
        if pointList.count == 4 {
            self.attempt1TextField.text = pointList[0]
            self.attempt2TextField.text = pointList[1]
            self.attempt3TextField.text = pointList[2]
            self.attempt4TextField.text = pointList[3]
        }
    }
    
    // MARK: - Button Event Handlers
    
    /// Resets points distribution as user clicks on reset
    /// button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func resetButtonAction(_ sender: UIButton?) {
        self.attempt1TextField.text = "\(self.points / 1)"
        self.attempt2TextField.text = "\(self.points / 2)"
        self.attempt3TextField.text = "\(self.points / 3)"
        self.attempt4TextField.text = "\(self.points / 4)"
        
        self.poa = "\(self.points / 1),\(self.points / 2),\(self.points / 3),\(self.points / 4)"
        self.formattedPoa = "[1] \(self.points / 1); [2] \(self.points / 2), [3] \(self.points / 3); [4] \(self.points / 4)"
    }
    
    /// Checks if each points exceeded the allowable points
    /// per attempt. If yes, then it notifies the user about
    /// the error; otherwise, it assembles the required data
    /// and goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func saveButtonAction(_ sender: UIButton) {
        let exceeded = self.doPointsExceed(forTextFields: [self.attempt1TextField, self.attempt2TextField, self.attempt3TextField, self.attempt4TextField])
        
        if exceeded.0 && exceeded.1 != nil {
            let label = "Points exceed total allowable points!"
            HUD.flash(.label(label), onView: nil, delay: 3.5, completion: { (success) in
                exceeded.1!.becomeFirstResponder()
            })
            
            return
        }
        
        self.poa = "\(self.attempt1TextField.text!),\(self.attempt2TextField.text!),\(self.attempt3TextField.text!),\(self.attempt4TextField.text!)"
        self.formattedPoa = "[1] \(self.attempt1TextField.text!); [2] \(self.attempt2TextField.text!), [3] \(self.attempt3TextField.text!); [4] \(self.attempt4TextField.text!)"
        self.dismiss(animated: true) { self.delegate?.updatedPointsOnAttempt(self.poa, poaFormatted: self.formattedPoa) }
    }
    
    /// Checks if points entered for each attempt exceeds
    /// the allowable points per attempt or not.
    ///
    ///
    /// - parameter textFields: Array of UITextField (Attempts)
    fileprivate func doPointsExceed(forTextFields textFields: [UITextField]) -> (Bool, UITextField?) {
        for tf in textFields {
            if self.arfDataManager.intString(tf.text!) > self.points {
                return (true, tf)
            }
        }
        return (false, nil)
    }
    
    // MARK: - Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        /// Limit acceptable number of characters to 5
        if newText.count > 5 { return false }
        
        /// Accept only numeric data for points
        let numberSet = CharacterSet.decimalDigits
        if (string as NSString).rangeOfCharacter(from: numberSet.inverted).location != NSNotFound { return false }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if self.arfDataManager.intString(textField.text!) > self.points {
            let label = "Points exceed total allowable points!"
            HUD.flash(.label(label), onView: nil, delay: 3.5, completion: { (success) in
                textField.becomeFirstResponder()
            })
        }
    }

}
