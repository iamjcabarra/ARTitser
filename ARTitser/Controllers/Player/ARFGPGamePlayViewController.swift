//
//  ARFGPGamePlayViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 10/02/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import ARCL
import SceneKit
import CoreLocation
import MapKit
import AVFoundation
import PKHUD

protocol ARFGPGamePlayViewControllerDelegate: class {
    func quitGame()
}

class ARFGPGamePlayViewController: UIViewController, AVAudioPlayerDelegate, ARFGPGameClueViewControllerDelegate, ARFGPGameTreasureViewControllerDelegate, ARFGPGamePauseViewControllerDelegate, ARFGPGameMapViewControllerDelegate, ARFGPGamePlayResultViewControllerDelegate {
    
    @IBOutlet var topView: UIView!
    @IBOutlet var actualGameView: UIView!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var mapBackView: UIView!
    @IBOutlet var mapImageView: UIImageView!
    @IBOutlet var mapButton: UIButton!
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var clueListView: UIView!
    @IBOutlet var clueListImageView: UIImageView!
    @IBOutlet var clueListButton: UIButton!
    @IBOutlet var exitView: UIView!
    @IBOutlet var exitImageView: UIImageView!
    @IBOutlet var exitButton: UIButton!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var pauseView: UIView!
    @IBOutlet var pauseImageView: UIImageView!
    @IBOutlet var pauseButton: UIButton!
    @IBOutlet var clueRatioLabel: UILabel!
    
    weak var delegate: ARFGPGamePlayViewControllerDelegate?
    var classId: Int64 = 0
    var game: Game!
    
//    fileprivate var sceneLocationView = SceneLocationView()
    fileprivate var audioPlayer: AVAudioPlayer!
    fileprivate var sidekickImage: UIImage!
    fileprivate var order: Int64 = 0
    fileprivate var totalPoints: Int64 = 0
//    fileprivate var canShowModalView = true
    fileprivate var timer = Timer()
    fileprivate var isTimerRunning = false
    fileprivate var seconds: Int64 = 0
    fileprivate var resumeTapped = false
    fileprivate var isLast = false
//    fileprivate var isTreasure = false
    fileprivate var clues = ""
//    fileprivate var nextGameClue: GameClue? = nil
//    fileprivate var nextGameTreasure: GameTreasure? = nil
//    fileprivate var currentLocationLongitude: Double = 0.0
//    fileprivate var currentLocationLatitude: Double = 0.0
//    fileprivate var mapMarkTitle = ""
    fileprivate var isTimeOut = false
//    fileprivate var didStartLocationManager = false
//    fileprivate var locationNodes = [LocationNode]()
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - Location Manager
    
    fileprivate lazy var arfLocationManager: ARFLocationManager = {
        return ARFLocationManager.sharedInstance
    }()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configure other views
//        self.topView.backgroundColor = UIColor.black.withAlphaComponent(0)
//        self.bottomView.backgroundColor = UIColor.black.withAlphaComponent(0)
        
        /// Set sidekick image
//        let entitySidekick = ARFConstants.entity.SIDEKICK
//        let predicateSideKick = self.arfDataManager.predicate(forKeyPath: "ownedBy", exactValue: "\(self.arfDataManager.loggedUserId)")
//        let sidekick = self.arfDataManager.db.retrieveObject(forEntity: entitySidekick, filteredBy: predicateSideKick) as? Sidekick
//        let sidekickType = sidekick != nil ? sidekick!.type : 0
//        self.sidekickImage = sidekickType == 0 ? ARFConstants.image.GPV_SIDEKICK_A : ARFConstants.image.GPV_SIDEKICK_B
        self.sidekickImage = ARFConstants.image.GPV_SIDEKICK_A
        
        /// Handle button events
//        self.mapButton.addTarget(self, action: #selector(self.mapButtonAction(_:)), for: .touchUpInside)
//        self.clueListButton.addTarget(self, action: #selector(self.clueListButtonAction(_:)), for: .touchUpInside)
        self.pauseButton.addTarget(self, action: #selector(self.pauseButtonAction(_:)), for: .touchUpInside)
        self.exitButton.addTarget(self, action: #selector(self.exitButtonAction(_:)), for: .touchUpInside)
        
        /// Configure location manager
//        self.arfLocationManager.delegate = self
//        self.arfLocationManager.startUpdatingLocation()
    
        /// Configure background music
        self.playBackgroundMusic()
        
        /// Configure timer
        self.timerLabel.text = ""
        self.timerLabel.isHidden = self.game.isTimeBound == 1 ? false : true
        self.seconds = self.game.isTimeBound == 1 ? (self.game.minutes * 60) : 86400
        self.runTimer()
        
        /// Set clue ratio
        self.updateClueRatioLabel()
        
        loadStartingClue()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        /// Run scene
//        self.sceneLocationView.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
     
        /// Pause scene
//        self.sceneLocationView.pause()
        
        /// Stop location manager
//        self.arfLocationManager.stopUpdatingLocation()
        
        /// Stop background music
        self.audioPlayer.stop()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        /// Set scene view's bounds
//        self.sceneLocationView.frame = self.actualGameView.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Starting Clue
    
    /// Retrieves starting game clue object from
    /// core data
    fileprivate func loadStartingClue() {
        let entityGameClue = ARFConstants.entity.GAME_CLUE
        let predicateA = self.arfDataManager.predicate(forKeyPath: "gameId", exactValue: "\(self.game.id)")
        let predicateB = self.arfDataManager.predicate(forKeyPath: "id", exactValue: "\(self.game.startingClueId)")
        let predicateC = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateA, predicateB])
        
        if let sgc = self.arfDataManager.db.retrieveObject(forEntity: entityGameClue, filteredBy: predicateC) as? GameClue {
//            self.nextGameClue = sgc
//            self.loadSceneView(sgc.longitude, latitude: sgc.latitude)
            DispatchQueue.main.async {
                let data: [String: Any] = ["gameClue": sgc]
                self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_GAME_CLUE_VIEW, sender: data)
            }
        }
        else {
            let message = "Sorry, you can't start the assessment as its starting question was not configured properly."
            HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
    
//    // MARK: - Scene Location Helpers
//
//    /// Updates scene view with clue or treasure at
//    /// location as well as arrows.
//    ///
//    /// - parameters:
//    ///     - longitude : A Double
//    ///     - latitude  : A Double
//    fileprivate func loadSceneView(_ longitude: Double, latitude: Double) {
//        for locationNode in self.locationNodes {
//            self.sceneLocationView.removeLocationNode(locationNode: locationNode)
//        }
//
//        let fromLocation = CLLocationCoordinate2DMake(self.currentLocationLatitude, self.currentLocationLongitude)
//        let toLocation = CLLocationCoordinate2DMake(latitude, longitude)
//
//        let frDestinationCoordinate = CLLocationCoordinate2D(latitude: self.currentLocationLatitude, longitude: self.currentLocationLongitude)
//        let frDestinationLocation = CLLocation(coordinate: frDestinationCoordinate, altitude: ARFConstants.gamePlay.ALTITUDE)
//        let frDestinationImage = UIImage(named: "imgGPVStartingOrigin")!
//        let frDestinationLocationNode = LocationAnnotationNode(location: frDestinationLocation, image: frDestinationImage)//LocationAnnotationNode(location: frDestinationLocation, image: frDestinationImage, isStep: true)
//        frDestinationLocationNode.scaleRelativeToDistance = true
//        self.sceneLocationView.showAxesNode = false
//        self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: frDestinationLocationNode)
//        self.locationNodes.append(frDestinationLocationNode)
//
//        self.arfLocationManager.getPolylineRoutes(from: fromLocation, to: toLocation) { (result) in
//            let roadSignImage = UIImage(named: "imgGPVBlankRoadSign")!
//            let transparentImage = UIImage(named: "imgGPVTransparent")!
//            var routed = false
//
//            if let r = result, let routes = r["routes"] as? [[String: Any]] {
//               for route in routes {
//                    let startLocationLat = route["start_location_lat"] as! Double
//                    let startLocationLng = route["start_location_lng"] as! Double
//                    let endLocationLat = route["end_location_lat"] as! Double
//                    let endLocationLng = route["end_location_lng"] as! Double
//                    let maneuver = route["maneuver"] as! String
//                    let formattedManeuver = maneuver.replacingOccurrences(of: "-", with: " ").uppercased()
//
//                    let startCoordinate = CLLocationCoordinate2D(latitude: startLocationLat, longitude: startLocationLng)
//                    let startLocation = CLLocation(coordinate: startCoordinate, altitude: ARFConstants.gamePlay.ALTITUDE)
//                    let startImage = self.textToImage(drawText: formattedManeuver, inImage: roadSignImage)
//                    let startLocationNode = LocationAnnotationNode(location: startLocation, image: startImage)//LocationAnnotationNode(location: startLocation, image: startImage, isStep: true)
//                    startLocationNode.scaleRelativeToDistance = true
//                    self.sceneLocationView.showAxesNode = false
//                    self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: startLocationNode)
//                    self.locationNodes.append(startLocationNode)
//
//                    let endCoordinate = CLLocationCoordinate2D(latitude: endLocationLat, longitude: endLocationLng)
//                    let endLocation = CLLocation(coordinate: endCoordinate, altitude: ARFConstants.gamePlay.ALTITUDE)
//                    let endImage = self.textToImage(drawText: "", inImage: transparentImage)
//                    let endLocationNode = LocationAnnotationNode(location: endLocation, image: endImage)//LocationAnnotationNode(location: endLocation, image: endImage, isStep: true)
//                    endLocationNode.scaleRelativeToDistance = true
//                    self.sceneLocationView.showAxesNode = false
//                    self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: endLocationNode)
//                    self.locationNodes.append(endLocationNode)
//
//                    let fr = startLocationNode.position
//                    let to = endLocationNode.position
//                    let image = UIImage(named: "imgGPVGamePlayArrow")!
//                    let node = self.makeCylinder(fromPosition: fr, toPosition: to, radius: 1.0, image: image, transparency: 0)
//                    node.position = SCNVector3Zero
//                    self.sceneLocationView.scene.rootNode.addChildNode(node)
//                }
//
//                routed = routes.count > 0 ? true : false
//            }
//            else {
//                DispatchQueue.main.async {
//                    let message = "Directions Not Available."
//                    HUD.flash(.label(message), onView: nil, delay: 3.5, completion: { (success) in })
//                }
//            }
//
//            let toDestinationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//            let toDestinationLocation = CLLocation(coordinate: toDestinationCoordinate, altitude: ARFConstants.gamePlay.ALTITUDE)
//            let toDestinationImage = self.isTreasure ? UIImage(named: "imgGPVTreasure")! : UIImage(named: "imgGPVStar")!
//            let toDestinationLocationNode = LocationAnnotationNode(location: toDestinationLocation, image: toDestinationImage)
//            toDestinationLocationNode.scaleRelativeToDistance = true
//            self.sceneLocationView.showAxesNode = false
//            self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: toDestinationLocationNode)
//            self.locationNodes.append(toDestinationLocationNode)
//
//            if !routed {
//                let fr = frDestinationLocationNode.position
//                let to = toDestinationLocationNode.position
//                let image = UIImage(named: "imgGPVGamePlayArrow")!
//                let node = self.makeCylinder(fromPosition: fr, toPosition: to, radius: 1.0, image: image, transparency: 0)
//                node.position = SCNVector3Zero
//                self.sceneLocationView.scene.rootNode.addChildNode(node)
//            }
//        }
//
//        self.actualGameView.addSubview(self.sceneLocationView)
//    }
    
    /// Updates label of clue ratio.
    fileprivate func updateClueRatioLabel() {
        let clueCount = self.game.clues?.count
        self.clueRatioLabel.text = "\(self.order) / \(clueCount ?? 0)"
    }
    
    // MARK: - Convert Text to Image
    
    /// Draws text to an image.
    ///
    /// - parameters:
    ///     - text  : A String identifying text to draw
    ///     - image : A UIImage identifying image
    fileprivate func textToImage(drawText text: String, inImage image: UIImage) -> UIImage {
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        let font = UIFont(name: "Helvetica-Bold", size: 50)!
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = NSTextAlignment.center
        let textColor = UIColor.white
        let attributes = [NSAttributedStringKey.font: font, NSAttributedStringKey.paragraphStyle: textStyle, NSAttributedStringKey.foregroundColor: textColor]
        let textH = font.lineHeight
        let textY = (image.size.height - textH) / 2
        let textRect = CGRect(x: 0, y: textY, width: image.size.width, height: textH)
        text.draw(in: textRect.integral, withAttributes: attributes)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result!
    }
    
    // MARK: - Background Music Handler
    
    /// Plays background music repeatedly.
    fileprivate func playBackgroundMusic() {
        if let audioPath = Bundle.main.path(forResource: "background_001", ofType: "wav"), let audioUrl = URL(string: audioPath) {
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
                self.audioPlayer.delegate = self
                self.audioPlayer.play()
            }
            catch {
                print("ERROR: Can't play background music!")
            }
        }
    }
    
    // MARK: - Button Event Handlers
    
//    /// Shows clue's location on map as user
//    /// clicks on map button.
//    ///
//    /// - parameter sender: A UIButton
//    @objc fileprivate func mapButtonAction(_ sender: UIButton) {
//        if self.isLast {
//            if let gt = self.nextGameTreasure {
//                self.canShowModalView = false
//                self.mapMarkTitle = "Treasure"
//                let data: [String: Any] = ["longitude": gt.longitude, "latitude": gt.latitude, "address": gt.locationName ?? ""]
//                let identifier = ARFConstants.segueIdentifier.GPV_GAME_MAP_VIEW
//                self.performSegue(withIdentifier: identifier, sender: data)
//            }
//        }
//        else {
//            if let gc = self.nextGameClue {
//                self.canShowModalView = false
//                self.mapMarkTitle = "Clue"
//                let data: [String: Any] = ["longitude": gc.longitude, "latitude": gc.latitude, "address": gc.locationName ?? ""]
//                let identifier = ARFConstants.segueIdentifier.GPV_GAME_MAP_VIEW
//                self.performSegue(withIdentifier: identifier, sender: data)
//            }
//        }
//    }
    
//    /// Presents an action controller which shows
//    /// list of clues gathered by user.
//    ///
//    /// - parameter sender: A UIButton
//    @objc fileprivate func clueListButtonAction(_ sender: UIButton) {
//        let title = "Gathered Clues"
//        let message = "\(self.clues)"
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//
//        let action = UIAlertAction(title: "Close", style: .cancel) { (Alert) -> Void in
//            alert.dismiss(animated: true, completion: nil)
//        }
//
//        alert.addAction(action)
//        self.present(alert, animated: true, completion: nil)
//    }
    
    /// Runs or invalidates timer as user clicks
    /// on pause button.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func pauseButtonAction(_ sender: UIButton?) {
        if !self.resumeTapped {
            self.timer.invalidate()
            self.resumeTapped = true
            self.audioPlayer.pause()
//            self.canShowModalView = false
            
            DispatchQueue.main.async {
                let identifier = ARFConstants.segueIdentifier.GPV_GAME_PAUSE_VIEW
                self.performSegue(withIdentifier: identifier, sender: nil)
            }
        }
        else {
            self.runTimer()
            self.resumeTapped = false
            self.audioPlayer.play()
//            self.canShowModalView = true
        }
    }
    
    /// Asks user if he really wants to exit from
    /// the game or not. If yes, then goes back to
    /// the game view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func exitButtonAction(_ sender: UIButton) {
        self.timer.invalidate()
        self.audioPlayer.pause()
//        self.canShowModalView = false
        
        let title = "Quit Assessment"
        let message = "Are you sure you want to quit? Any changes you have made will not be saved."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let posAction = UIAlertAction(title: "Yes", style: .default) { (Alert) -> Void in
            DispatchQueue.main.async(execute: {
                self.dismiss(animated: true, completion: {
                    self.delegate?.quitGame()
                })
            })
        }
        
        let negAction = UIAlertAction(title: "No", style: .cancel) { (Alert) -> Void in
            DispatchQueue.main.async(execute: {
                self.runTimer()
                self.audioPlayer.play()
//                self.canShowModalView = true
                alert.dismiss(animated: true, completion: nil)
            })
        }
        
        alert.addAction(posAction)
        alert.addAction(negAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Timer Handler
    
    /// Runs timer.
    fileprivate func runTimer() {
        let selector = #selector(self.updateTimer)
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: selector, userInfo: nil, repeats: true)
    }
    
    /// Updates timer. Goes to submitting of game
    /// result as timer has exhausted.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func updateTimer() {
        if self.seconds < 1 {
            self.timer.invalidate()
            self.pauseButton.isUserInteractionEnabled = false
            self.audioPlayer.stop()
            self.isTimeOut = true
            self.showGameResultView()
        }
        else {
            self.seconds = self.seconds - 1
            self.timerLabel.text = timeString(time: TimeInterval(self.seconds))
            
            if self.seconds < 10 {
                self.timerLabel.textColor = UIColor.red
                self.timerLabel.font = UIFont.boldSystemFont(ofSize: 17)
            }
        }
    }
    
    /// Formats timer.
    ///
    /// - parametr time: A TimeInterva object
    fileprivate func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    // MARK: - Game View Result
    
    /// Shows game result view but before that, it
    /// dismisses first any view controller that is
    /// currently presented.
    fileprivate func showGameResultView() {
        if let vc = self.presentedViewController {
            vc.dismiss(animated: true, completion: {
                self.processSubmissionOfGameResult()
            })
        }
        else {
            self.processSubmissionOfGameResult()
        }
    }
    
    /// Requests submission of game result to server.
    /// It then shows the game result view if request
    /// succeeded.
    fileprivate func processSubmissionOfGameResult() {
        HUD.show(.rotatingImage(ARFConstants.image.GEN_PROGRESS))
        
        self.arfDataManager.requestSubmitGameResult(forGameWithId: "\(self.game.id)", completion: { (result) in
            let status = result!["status"] as! Int
            
            if status == 0 {
                DispatchQueue.main.async(execute: {
                    HUD.hide()
//                    for locationNode in self.locationNodes { self.sceneLocationView.removeLocationNode(locationNode: locationNode) }
//                    self.sceneLocationView.pause()
                    let identifier = ARFConstants.segueIdentifier.GPV_GAME_PLAY_RESULT_VIEW
                    self.performSegue(withIdentifier: identifier, sender: nil)
                })
            }
            else {
                DispatchQueue.main.async {
                    HUD.hide()
                    let subtitle = result!["message"] as! String
                    HUD.flash(.labeledError(title: "Oops!", subtitle: subtitle), onView: nil, delay: 3.5, completion: { (success) in })
                }
            }
        })
    }
    
    // MARK: - Scene Node Manager
    
//    /// Updates timer. Goes to submitting of game
//    /// Connects two scene nodes by a cylinder.
//    ///
//    /// - parameters:
//    ///     - fr: A SCNVector3 identifying 1st node's position
//    ///     - to: A SCNVector3 identifying 2nd node's position
//    ///     - color: A UIColor identifying returned node's color
//    ///     - radius: A CGFloat identifying cylinder's radius
//    ///     - transparency: A CGFloat identifying cylinder's transparency
//    fileprivate func makeCylinder(fromPosition fr: SCNVector3, toPosition to: SCNVector3, radius: CGFloat, image: UIImage, transparency: CGFloat) -> SCNNode {
//        let height = CGFloat(GLKVector3Distance(SCNVector3ToGLKVector3(fr), SCNVector3ToGLKVector3(to)))
//        let frNode = SCNNode()
//        let toNode = SCNNode()
//        let fnNode = SCNNode()
//        let zAxisNode = SCNNode()
//        let cylinderGeometry = SCNCylinder(radius: radius, height: height)
//        let cylinder = SCNNode(geometry: cylinderGeometry)
//        let material = SCNMaterial()
//
//        frNode.position = fr
//        toNode.position = to
//        zAxisNode.eulerAngles.x = Float(CGFloat(Double.pi / 2))
//        material.diffuse.contents = image
//        cylinderGeometry.materials = [material]
//        cylinder.position.y = Float(-height / 2)
//        zAxisNode.addChildNode(cylinder)
//
//        if (fr.x > 0.0 && fr.y < 0.0 && fr.z < 0.0 && to.x > 0.0 && to.y < 0.0 && to.z > 0.0) {
//            toNode.addChildNode(zAxisNode)
//            toNode.constraints = [SCNLookAtConstraint(target: frNode)]
//            fnNode.addChildNode(toNode)
//        }
//        else if (fr.x < 0.0 && fr.y < 0.0 && fr.z < 0.0 && to.x < 0.0 && to.y < 0.0 && to.z > 0.0) {
//            toNode.addChildNode(zAxisNode)
//            toNode.constraints = [SCNLookAtConstraint(target: frNode)]
//            fnNode.addChildNode(toNode)
//        }
//        else if (fr.x < 0.0 && fr.y > 0.0 && fr.z < 0.0 && to.x < 0.0 && to.y > 0.0 && to.z > 0.0) {
//            toNode.addChildNode(zAxisNode)
//            toNode.constraints = [SCNLookAtConstraint(target: frNode)]
//            fnNode.addChildNode(toNode)
//        }
//        else if (fr.x > 0.0 && fr.y > 0.0 && fr.z < 0.0 && to.x > 0.0 && to.y > 0.0 && to.z > 0.0) {
//            toNode.addChildNode(zAxisNode)
//            toNode.constraints = [SCNLookAtConstraint(target: frNode)]
//            fnNode.addChildNode(toNode)
//        }
//        else {
//            frNode.addChildNode(zAxisNode)
//            frNode.constraints = [SCNLookAtConstraint(target: toNode)]
//            fnNode.addChildNode(frNode)
//        }
//
//        return fnNode
//    }
    
//    /// Animates color of node forever.
//    ///
//    /// - parameter node: A SCNNode identifying the node
//    fileprivate func animateNode(_ node: SCNNode) {
//        node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
//        let changeColor = SCNAction.customAction(duration: 1) { (newNode, elapsedTime) -> () in
//            let color = UIColor(red: elapsedTime, green: 1, blue: 0, alpha: 1)
//            newNode.geometry?.firstMaterial?.diffuse.contents = color
//        }
//        let action = SCNAction.repeatForever(SCNAction.sequence([changeColor]))
//        node.runAction(action)
//    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_GAME_CLUE_VIEW {
            guard let data = sender as? [String: Any], let gameClue = data["gameClue"] as? GameClue else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameClueView = segue.destination as! ARFGPGameClueViewController
            gameClueView.classId = self.classId
            gameClueView.gameClue = gameClue
            gameClueView.isLast = self.isLast
            gameClueView.delegate = self
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_GAME_TREASURE_VIEW {
            guard let data = sender as? [String: Any], let gameTreasure = data["gameTreasure"] as? GameTreasure else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameTreasureView = segue.destination as! ARFGPGameTreasureViewController
            gameTreasureView.classId = self.classId
            gameTreasureView.gameTreasure = gameTreasure
            gameTreasureView.subTotalPoints = self.totalPoints
            gameTreasureView.clues = self.clues
            gameTreasureView.delegate = self
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_GAME_PLAY_RESULT_VIEW {
            let gameResultView = segue.destination as! ARFGPGamePlayResultViewController
            gameResultView.isTimeOut = self.isTimeOut
            gameResultView.totalPoints = self.totalPoints
            gameResultView.delegate = self
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_GAME_PAUSE_VIEW {
            let gamePauseView = segue.destination as! ARFGPGamePauseViewController
            gamePauseView.delegate = self
        }
        
        if segue.identifier == ARFConstants.segueIdentifier.GPV_GAME_MAP_VIEW {
            guard let data = sender as? [String: Any], let longitude = data["longitude"] as? Double, let latitude = data["latitude"] as? Double, let address = data["address"] as? String else {
                print("ERROR: Can't parse segue sender's data!")
                return
            }
            
            let gameMapView = segue.destination as! ARFGPGameMapViewController
            gameMapView.nextPositionLongitude = longitude
            gameMapView.nextPositionLatitude = latitude
            gameMapView.nextPositionAddress = address
//            gameMapView.mapMarkTitle = self.mapMarkTitle
//            gameMapView.currentPositionLongitude = self.currentLocationLongitude
//            gameMapView.currentPositionLatitude = self.currentLocationLatitude
            gameMapView.delegate = self
        }
        
    }
    
//    // MARK: - Location Manager Delegate
//
//    func tracingLocation(_ currentLocation: CLLocation) {
//        print("LOCATION MANAGER: \(currentLocation)")
//
//        self.currentLocationLongitude = currentLocation.coordinate.longitude
//        self.currentLocationLatitude = currentLocation.coordinate.latitude
//
//        if !self.didStartLocationManager {
//            self.loadStartingClue()
//            self.didStartLocationManager = true
//        }
//
//        let gameStatus = self.arfDataManager.getStatusOfGame(withId: "\(self.game.id)")
//        let hasGameFinished = gameStatus.0
//        self.isLast = gameStatus.1
//
//        if hasGameFinished {
//            if self.canShowModalView {
//                self.arfLocationManager.retrieveTreasure(atCurrentLocation: currentLocation, forGameWithId: "\(self.game.id)", completion: { (result) in
//                    if let r = result as? [String: GameTreasure], let gameTreasure = r["gameTreasure"] {
//                        DispatchQueue.main.async {
//                            self.canShowModalView = false
//                            let data: [String: Any] = ["gameTreasure": gameTreasure]
//                            self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_GAME_TREASURE_VIEW, sender: data)
//                        }
//                    }
//                })
//            }
//        }
//        else {
//            if self.canShowModalView {
//                self.arfLocationManager.retrieveClue(atCurrentLocation: currentLocation, order: self.order, forGameWithId: "\(self.game.id)") { (result) in
//                    if let r = result as? [String: GameClue], let gameClue = r["gameClue"] {
//                        DispatchQueue.main.async {
//                            self.canShowModalView = false
//                            let data: [String: Any] = ["gameClue": gameClue]
//                            self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_GAME_CLUE_VIEW, sender: data)
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    func tracingLocationDidFailWithError(_ error: NSError) {
//        print("LOCATION MANAGER: \(error.localizedDescription)")
//    }
    
    // MARK: - Audio Player Delegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            self.audioPlayer.delegate = nil
            self.playBackgroundMusic()
        }
    }
    
    // MARK: - ARFGPGameClueViewControllerDelegate
    
    func proceed(_ proceed: Bool, points: Int64, clue: String) {
        if proceed {
            self.order = self.order + 1
            self.totalPoints = self.totalPoints + points
            self.clues = "\(self.clues == "" ? "" : "\(self.clues), ")\(clue)"
            
            let gameStatus = self.arfDataManager.getStatusOfGame(withId: "\(self.game.id)")
            let hasGameFinished = gameStatus.0
            
//            if hasGameFinished {
//                self.arfLocationManager.retrieveTreasure(forGameWithId: "\(self.game.id)", completion: { (result) in
//                    if let r = result as? [String: GameTreasure], let gameTreasure = r["gameTreasure"] {
//                        self.isTreasure = true
//                        self.loadSceneView(gameTreasure.longitude, latitude: gameTreasure.latitude)
//                        self.nextGameTreasure = gameTreasure
//                    }
//                })
//            }
//            else {
//                self.arfLocationManager.retrieveClue(withOrder: self.order, forGameWithId: "\(self.game.id)", completion: { (result) in
//                    if let r = result as? [String: GameClue], let gameClue = r["gameClue"] {
//                        self.isTreasure = false
//                        self.loadSceneView(gameClue.longitude, latitude: gameClue.latitude)
//                        self.nextGameClue = gameClue
//                    }
//                })
//            }
            
            if hasGameFinished {
                self.timer.invalidate()
                self.pauseButton.isUserInteractionEnabled = false
                self.audioPlayer.stop()
                self.isTimeOut = false
                self.showGameResultView()
            }
            else {
                self.arfLocationManager.retrieveClue(withOrder: self.order, forGameWithId: "\(self.game.id)", completion: { (result) in
                    if let r = result as? [String: GameClue], let gameClue = r["gameClue"] {
                        DispatchQueue.main.async {
                            let data: [String: Any] = ["gameClue": gameClue]
                            self.performSegue(withIdentifier: ARFConstants.segueIdentifier.GPV_GAME_CLUE_VIEW, sender: data)
                        }
                    }
                })
            }
        }
        
//        self.canShowModalView = true
        self.scoreLabel.text = "\(self.totalPoints)"
        self.updateClueRatioLabel()
    }
    
    // MARK: - ARFGPGameTreasureViewControllerDelegate
    
    func finish(_ finish: Bool, points: Int64, showResultView: Bool) {
//        if finish {
////            self.canShowModalView = false
//            self.timer.invalidate()
//            self.pauseButton.isUserInteractionEnabled = false
//            self.audioPlayer.stop()
//            
//            if !showResultView {
//                self.totalPoints = self.totalPoints + points
//                self.scoreLabel.text = "\(self.totalPoints)"
//            }
//            else {
//                self.isTimeOut = false
//                self.showGameResultView()
//            }
//        }
//        
////        if !finish { self.canShowModalView = true }
    }
    
    
    // MARK: - ARFGPGamePauseViewControllerDelegate
    
    func resumeGame() {
        self.pauseButtonAction(nil)
    }
    
    // MARK: - ARFGPGameMapViewControllerDelegate
    
    func didMapViewDismiss(_ dismiss: Bool) {
//        self.canShowModalView = true
    }
    
    // MARK: = ARFGPGamePlayResultViewControllerDelegate
    
    func goBackToGameListView() {
        DispatchQueue.main.async(execute: {
            self.dismiss(animated: true, completion: {
                self.delegate?.quitGame()
            })
        })
    }
}

