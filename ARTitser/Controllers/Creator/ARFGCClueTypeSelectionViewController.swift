//
//  ARFGCClueTypeSelectionViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 21/12/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import UIKit
import PKHUD

class ARFGCClueTypeSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ARFGCClueCreationMultipleChoiceViewControllerDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var continueButton: UIButton!
    
    var loggedUserId: Int64 = 0
    var clueId: Int64 = 0
    var isCreation = false
    
    fileprivate var clueTypes = [[String: Any]]()
    fileprivate var selectedClueType: Int64 = ARFConstants.clueType.ID
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = "Select Question Type"
        
        /// Configure background color
        let backgroundColor = self.isCreation ? ARFConstants.color.GEN_CREATE_ACTION : ARFConstants.color.GEN_UPDATE_ACTION
        self.navigationBar.barTintColor = backgroundColor
        self.bottomView.backgroundColor = backgroundColor
        self.view.backgroundColor = backgroundColor
        
        /// Populate array of clue types
        self.clueTypes = [["type": ARFConstants.clueType.MC,
                           "image": ARFConstants.image.GCV_CLUE_TYPE_MC_BIG,
                           "title": "Multiple Choice",
                           "description": "Student is asked to select the best possible answer out of four choices from a list."]]
        
        /// Set estimated height for tableview cells
        self.tableView.estimatedRowHeight = 140.0
        
        /// Make tableview cell's height dynamic
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        /// Configure buttons
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        self.continueButton.addTarget(self, action: #selector(self.continueButtonAction(_:)), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view as user clicks on
    /// cancel button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Presents clue details view if deep copying of
    /// clue object succeeded where user can create a
    /// new clue.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func continueButtonAction(_ sender: UIButton) {
        if self.selectedClueType == ARFConstants.clueType.MC {
            self.arfDataManager.deepCopyClueObject(nil, type: self.selectedClueType, owner: self.loggedUserId, isCreation: true) { (result) in
                if result != nil {
                    DispatchQueue.main.async {
                        let clue = result!["clue"] as! DeepCopyClue
                        let data: [String: Any] = ["clue": clue, "isCreation": true]
                        self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GCV_CLUE_CREATION_MC_VIEW, sender: data)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        let subtitle = ARFConstants.message.DEFAULT_ERROR
                        HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                    }
                }
            }
        }
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.clueTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ARFConstants.cellIdentifier.CLUE_TYPE_SELECTION, for: indexPath) as! ARFGCClueTypeSelectionTableViewCell
        let clueType = self.clueTypes[indexPath.row]
        
        cell.clueTypeImage.image = clueType["image"] as? UIImage
        cell.clueTypeTitleLabel.text = clueType["title"] as? String
        cell.clueTypeDescriptionLabel.text = clueType["description"] as? String
        
        return cell
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let clueType = self.clueTypes[indexPath.row]
        self.selectedClueType = clueType["type"] as! Int64
        self.continueButton.shake()
        self.continueButton.flash()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GCV_CLUE_CREATION_MC_VIEW {
            guard let data = sender as? [String: Any], let clue = data["clue"] as? DeepCopyClue, let isCreation = data["isCreation"] as? Bool  else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let clueCreationMCView = segue.destination as! ARFGCClueCreationMultipleChoiceViewController
            clueCreationMCView.clue = clue
            clueCreationMCView.isCreation = isCreation
            clueCreationMCView.delegate = self
        }
        
    }
    
    // MARK: - ARFGCClueCreationMultipleChoiceViewControllerDelegate
    
    func requestUpdateView() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }

}
