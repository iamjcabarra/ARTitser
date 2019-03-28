//
//  ARFGPGameTreasure3dViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 11/03/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation
import PKHUD

protocol ARFGPGameTreasure3dViewControllerDelegate: class {
    func showResultView()
}

class ARFGPGameTreasure3dViewController: UIViewController {
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var infoButton: UIButton!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var ttsView: UIView!
    @IBOutlet var ttsButton: UIButton!
    
    weak var delegate: ARFGPGameTreasure3dViewControllerDelegate?
    var treasure: GameTreasure!
    
    fileprivate var speechSynthesizer = AVSpeechSynthesizer()
    fileprivate var isDescriptionHidden = true
    fileprivate var model3dCount = 0
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Set title for navigation
        self.navigationBar.topItem?.title = self.treasure.game?.name ?? ""
        
        /// Handle button events
        self.ttsButton.addTarget(self, action: #selector(self.ttsButtonAction(_:)), for: .touchUpInside)
        self.cancelButton.addTarget(self, action: #selector(self.cancelButtonAction(_:)), for: .touchUpInside)
        self.infoButton.addTarget(self, action: #selector(self.infoButtonAction(_:)), for: .touchUpInside)
        
        /// Set description
        self.descriptionLabel.text = self.treasure.treasureDescription ?? ""
        
        /// Hide description
        self.scrollView.isHidden = true
        self.ttsView.isHidden = true
        self.ttsButton.isHidden = true
        
        /// Configure scene's lightning
        self.configureLighting()
        
        /// Configure tap gesture
        self.addTapGestureToSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Configure scene view
        self.setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        /// Stop scene view's session
        self.sceneView.session.pause()
        
        /// Stop speech synthesizer
        self.speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Scene Helpers
    
    /// Sets up scene view.
    fileprivate func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    /// Configures scene's lightning
    fileprivate func configureLighting() {
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.automaticallyUpdatesLighting = true
    }
    
    // MARK: - Button Event Handlers
    
    /// Goes back to the previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func cancelButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true) { self.delegate?.showResultView() }
    }
    
    /// Shows selected treasure's description.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func infoButtonAction(_ sender: UIButton) {
        self.scrollView.isHidden = self.isDescriptionHidden
        self.ttsView.isHidden = self.isDescriptionHidden
        self.ttsButton.isHidden = self.isDescriptionHidden
        self.isDescriptionHidden = self.isDescriptionHidden ? false : true
    }
    
    /// Voices out treasure's description.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func ttsButtonAction(_ sender: UIButton) {
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: self.treasure.treasureDescription ?? "")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        self.speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Tap Gesture Recognizer
    
    /// Places 3D model on the view as user
    /// taps on the plane.
    ///
    /// - parameter recognizer: A tap gesture recognizer
    fileprivate func addTapGestureToSceneView() {
        let action = #selector(self.add3dModel(withGestureRecognizer:))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    /// Places 3D model on a plane where user
    /// just tapped.
    ///
    /// - parameter recognizer: A tap gesture recognizer
    @objc func add3dModel(withGestureRecognizer recognizer: UIGestureRecognizer) {
        if self.model3dCount == 0 {
            let tapLocation = recognizer.location(in: self.sceneView)
            let hitTestResults = self.sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
            
            guard let hitTestResult = hitTestResults.first else { return }
            let translation = hitTestResult.worldTransform.translation
            let x = translation.x
            let y = translation.y
            let z = translation.z
//            let sceneName = self.retrieveSceneName()
//
//            if sceneName == "" {
//                let message = "\(self.treasure.name ?? "") doesn't have 3D model."
//                HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in
//                    self.sceneView.session.pause()
//                    self.model3dCount = self.model3dCount + 1
//                })
//
//                return
//            }
            
//            guard let scene = SCNScene(named: "ARF3dModels.scnassets/\(sceneName).scn"),
//                let sceneNode = scene.rootNode.childNode(withName: sceneName, recursively: false)
//                else { return }
//
//            sceneNode.position = SCNVector3(x, y, z)
//            self.sceneView.scene.rootNode.addChildNode(sceneNode)
//            self.model3dCount = self.model3dCount + 1
            
            guard let scene = SCNScene(named: "ARF3dModels.scnassets/\(self.treasure.model3dLocalName ?? "")") else { return }
        
            let sceneNode = SCNNode()
            let nodeArray = scene.rootNode.childNodes
            for childNode in nodeArray { sceneNode.addChildNode(childNode as SCNNode) }
            
            sceneNode.position = SCNVector3(x, y, z)
//            let position = SCNVector3(x: 0, y: 0, z: -2)
//            updatePositionAndOrientationOf(sceneNode, withPosition: position, relativeTo: scene.rootNode)
            self.sceneView.scene.rootNode.addChildNode(sceneNode)
            self.model3dCount = self.model3dCount + 1
        }
    }
    
//    /// Returns name of scene in scene catalog
//    /// dependent on the image local name.
//    fileprivate func retrieveSceneName() -> String {
//        let model3dLocalName = (self.treasure.model3dLocalName ?? "").replacingOccurrences(of: " ", with: "")
//        var sceneName = ""
//        if model3dLocalName.lowercased() == "heart.dae" { sceneName = "heart" }
//        if model3dLocalName.lowercased() == "wolf.dae" { sceneName = "wolf" }
//        if model3dLocalName.lowercased() == "model_3d_003.scn" { sceneName = "model_3d_003" }
//        return sceneName
//    }
    
//    fileprivate func updatePositionAndOrientationOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) {
//        let referenceNodeTransform = matrix_float4x4(referenceNode.transform)
//        
//        // Setup a translation matrix with the desired position
//        var translationMatrix = matrix_identity_float4x4
//        translationMatrix.columns.3.x = position.x
//        translationMatrix.columns.3.y = position.y
//        translationMatrix.columns.3.z = position.z
//        
//        // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
//        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
//        node.transform = SCNMatrix4(updatedTransform)
//    }
}

/// Handles Scene View's Delegates
extension ARFGPGameTreasure3dViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if self.model3dCount > 0 { return }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        plane.materials.first?.diffuse.contents = UIColor(hex: "fdfcee").withAlphaComponent(0.05)
        
        let planeNode = SCNNode(geometry: plane)
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if self.model3dCount > 0 { return }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
}
