//
//  ARFGPGameMapViewController.swift
//  ARFollow
//
//  Created by Julius Abarra on 11/03/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import GoogleMaps

protocol ARFGPGameMapViewControllerDelegate: class {
    func didMapViewDismiss(_ dismiss: Bool)
}

class ARFGPGameMapViewController: UIViewController {
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var exitView: UIView!
    @IBOutlet var exitImageView: UIImageView!
    @IBOutlet var exitButton: UIButton!
    
    weak var delegate: ARFGPGameMapViewControllerDelegate?
    
    var nextPositionLongitude: Double = 0.0
    var nextPositionLatitude: Double = 0.0
    var nextPositionAddress = ""
    var currentPositionLongitude: Double = 0.0
    var currentPositionLatitude: Double = 0.0
    var mapMarkTitle = ""
    
    // MARK: - Location Manager
    
    fileprivate lazy var arfLocationManager: ARFLocationManager = {
        return ARFLocationManager.sharedInstance
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Set properties for map view
        self.mapView.mapType = .normal
        self.mapView.isMyLocationEnabled = true
        
        /// Handle button event
        self.exitButton.addTarget(self, action: #selector(self.exitButtonAction(_:)), for: .touchUpInside)
        
        /// Configure map
        self.locateClue(withLongitude: self.nextPositionLongitude, latitude: self.nextPositionLatitude, address: self.nextPositionAddress)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Mapping Clue's Location
    
    /// Locates clue's location on the map
    ///
    /// - parameters:
    ///     - lng       : A Double identifying clue's longitude
    ///     - lat       : A Double identifying clue's latitude
    ///     - address   : A String identifying clue's address
    fileprivate func locateClue(withLongitude lng: Double, latitude lat: Double, address: String) {
        DispatchQueue.main.async(execute: {
            let toPosition = CLLocationCoordinate2DMake(lat, lng)
            let marker = GMSMarker(position: toPosition)
            let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: lng, zoom: 17)
            
            marker.title = self.mapMarkTitle
            marker.snippet = address
            marker.appearAnimation = .pop
            marker.icon = GMSMarker.markerImage(with: .green)
            marker.opacity = 1.0
            marker.map = self.mapView
            self.mapView.camera = camera
            
            let fromPosition = CLLocationCoordinate2DMake(self.currentPositionLatitude, self.currentPositionLongitude)
            self.drawLocationRoute(fromPosition: fromPosition, toPosition: toPosition)
        })
    }
    
    /// Draws routes on map.
    ///
    /// - parameters:
    ///     - fPosition : A CLLocationCoordinate2D which identifies the start position of destination
    ///     - tPosition : A CLLocationCoordinate2D which identifies the end position of destination
    fileprivate func drawLocationRoute(fromPosition fPosition: CLLocationCoordinate2D, toPosition tPosition: CLLocationCoordinate2D) {
        self.arfLocationManager.getPolylineRoute(from: fPosition, to: tPosition) { (result) in
            DispatchQueue.main.async(execute: {
                if let r = result, let points = r["points"] as? String, let path = GMSPath(fromEncodedPath: points) {
                    let polyline: GMSPolyline = GMSPolyline(path: path)
                    polyline.strokeWidth = 3.5
                    polyline.strokeColor = .blue
                    polyline.map = self.mapView
                }
            })
        }
    }
    
    // MARK: - Button Event Handler
    
    /// Dimisses this view and goes back to the
    /// previous view.
    ///
    /// - parameter sender: A UIButton
    @objc fileprivate func exitButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true) { self.delegate?.didMapViewDismiss(true) }
    }
    
}
