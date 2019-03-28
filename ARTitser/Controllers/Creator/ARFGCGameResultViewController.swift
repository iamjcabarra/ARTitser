//
//  ARFGCGameResultViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 12/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import WebKit
import PKHUD

class ARFGCGameResultViewController: UIViewController, WKNavigationDelegate, UIPopoverPresentationControllerDelegate, ARFGCGameResultClassSelectionPopoverDelegate {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var topView: UIView!
    @IBOutlet var selectClassTextField: UITextField!
    @IBOutlet var selectClassButton: UIButton!
    @IBOutlet var webView: WKWebView!
    
    var gameId: Int64 = 0
    var gameName = ""
    var classId: Int64 = 0
    var isCreator = true
    
    fileprivate var classSelectionPopover: ARFGCGameResultClassSelectionPopover!
    fileprivate var classCode = ""
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Hide or unhide search view
        self.topView.isHidden = self.isCreator ? false : true
        
        /// Configure navigation bar
        self.navigationBar.topItem?.title = "\(self.gameName) Result"
        
        /// Configure background color
        let backgroundColor = ARFConstants.color.GAV_NAV_DASHBOARD//self.isCreator ? UIColor.purple :  ARFConstants.color.GPV_NAV_DASHBOARD
        self.navigationBar.barTintColor = backgroundColor
        self.view.backgroundColor = backgroundColor
     
        /// Handle button events
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        self.selectClassButton.addTarget(self, action: #selector(self.selectClassButtonAction(_:)), for: .touchUpInside)
        
        /// Request game result if player
        if !self.isCreator { self.reloadGameResult() }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    /// Renders retrieved game result to web view.
    fileprivate func reloadGameResult() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.arfDataManager.requestRetrieveGameResult(forClassWithId: "\(self.classId)", andGameId: "\(self.gameId)") { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async {
                    let gameResult = result!["gameResult"] as! String
                    self.webView.loadHTMLString(gameResult, baseURL: nil)
                    self.webView.navigationDelegate = self
                    self.selectClassTextField.text = self.classCode
                }
            }
            else {
                DispatchQueue.main.async {
                    HUD.hide()
                    let subtitle = result!["message"] as! String
                    HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                }
            }
        }
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Presents a modal popup where user can select class.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func selectClassButtonAction(_ sender: UIButton) {
        self.classSelectionPopover = ARFGCGameResultClassSelectionPopover(nibName: "ARFGCGameResultClassSelectionPopover", bundle: nil)
        self.classSelectionPopover.delegate = self
        self.classSelectionPopover.modalPresentationStyle = .popover
        self.classSelectionPopover.preferredContentSize = CGSize(width: 200.0, height: 250.0)
        self.classSelectionPopover.popoverPresentationController?.permittedArrowDirections = .right
        self.classSelectionPopover.popoverPresentationController?.sourceView = sender
        self.classSelectionPopover.popoverPresentationController?.sourceRect = sender.bounds
        self.classSelectionPopover.popoverPresentationController?.delegate = self
        self.present(self.classSelectionPopover, animated: true, completion: nil)
    }
    
    // MARK: - Navigation Delegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { HUD.hide() }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            HUD.hide()
            let subtitle = ARFConstants.message.DEFAULT_ERROR
            HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
        }
    }
    
    // MARK: - Popover Presentation Controller Delegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    // MARK: - ARFGCGameResultClassSelectionPopoverDelegate
    
    func selectedClass(withId id: Int64, andCode code: String) {
        self.classId = id
        self.classCode = code
        self.reloadGameResult()
    }

}
