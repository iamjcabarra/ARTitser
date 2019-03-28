//
//  ARFLocationManager.swift
//  ARFollow
//
//  Created by Julius Abarra on 08/03/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import Foundation
import CoreLocation

protocol ARFLocationManagerDelegate {
    func tracingLocation(_ currentLocation: CLLocation)
    func tracingLocationDidFailWithError(_ error: NSError)
}

final class ARFLocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Singleton
    
    static let sharedInstance: ARFLocationManager = {
        return ARFLocationManager()
    }()
    
    // MARK: - Data Manager
    
    fileprivate lazy var arfDataManager: ARFDataManager = {
        return ARFDataManager.sharedInstance
    }()
    
    // MARK: - Properties
    
    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    var delegate: ARFLocationManagerDelegate?
    
    typealias ARFLocationManagerDoneBlock = (_ doneBlock: Bool) -> Void
    typealias ARFLocationManagerDataBlock = (_ dataBlock: [String: Any]?) -> Void
    typealias ARFLocationManagerGameTreasureBlock = (_ dataBlock: [String: GameTreasure?]?) -> Void
    typealias ARFLocationManagerGameClueBlock = (_ dataBlock: [String: GameClue?]?) -> Void
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        /// Instantiate location manager
        self.locationManager = CLLocationManager()
        
        /// Enable background location update
        self.locationManager?.allowsBackgroundLocationUpdates = true
        
        /// Check if already exists
        guard let locationManager = self.locationManager else { return }
        
        /// Check location manager authorization status
        if CLLocationManager.authorizationStatus() == .notDetermined { locationManager.requestAlwaysAuthorization() }
        
        /// Set location manager properties
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLLocationAccuracyBest
        locationManager.delegate = self
    }
    
    func startUpdatingLocation() {
        print("LOCATION MANAGER: Starting location updates...")
        self.locationManager?.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        print("LOCATION MANAGER: Stopping location updates...")
        self.locationManager?.stopUpdatingLocation()
    }
    
    func dispose() {
        self.locationManager = nil
        print("LOCATION MANAGER: Disposing singleton!")
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("ERROR: Can't get last user's location!")
            return
        }
        
        /// Singleton for current location
        self.currentLocation = location
        
        /// Use for real time update for current location
        self.updateLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.updateLocationDidFailWithError(error as NSError)
    }
    
    // MARK: - Private Methods
    
    fileprivate func updateLocation(_ currentLocation: CLLocation){
        guard let delegate = self.delegate else { return }
        delegate.tracingLocation(currentLocation)
    }
    
    fileprivate func updateLocationDidFailWithError(_ error: NSError) {
        guard let delegate = self.delegate else { return }
        delegate.tracingLocationDidFailWithError(error)
    }
    
    // MARK: - Locating Clue
    
    func retrieveClue(atCurrentLocation location: CLLocation, order: Int64, forGameWithId gameId: String, completion: @escaping ARFLocationManagerGameClueBlock) {
        let entityGameClue = ARFConstants.entity.GAME_CLUE
        let predicateGCA = self.arfDataManager.predicate(forKeyPath: "gameId", exactValue: gameId)
        let predicateGCB = self.arfDataManager.predicate(forKeyPath: "gpOrder", exactValue: "\(order)")
        let predicateGCC = self.arfDataManager.predicate(forKeyPath: "gpIsDone", notValue: "1")
        let predicateGCD = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateGCA, predicateGCB, predicateGCC])
        
        guard let gameClues = self.arfDataManager.db.retrieveObjects(forEntity: entityGameClue, filteredBy: predicateGCD) as? [GameClue] else {
            print("ERROR: Can't retrieve game clue objects!")
            completion(nil)
            return
        }
    
        var gcObjects = [GameClue]()
        
        for gameClue in gameClues {
            let latitude = gameClue.latitude
            let longitude = gameClue.longitude
            let clueLocation = CLLocation(latitude: latitude, longitude: longitude)
            let clueInMeters = clueLocation.distance(from: location)
            let distance = clueInMeters / 1000
            
            print("GAME CLUE: \(gameClue.clue ?? "")")
            print("LATITUDE: \(latitude)")
            print("LONGITUDE: \(longitude)")
            print("DISTANCE: km: \(distance) m: \(clueInMeters)")
            
            if clueInMeters <= ARFConstants.gamePlay.RADIUS { gcObjects.append(gameClue) }
        }
        
        completion(gcObjects.count > 0 ? ["gameClue": gcObjects.last] : nil)
    }
    
    func retrieveClue(withOrder order: Int64, forGameWithId gameId: String, completion: @escaping ARFLocationManagerGameClueBlock) {
        let entityGameClue = ARFConstants.entity.GAME_CLUE
        let predicateGCA = self.arfDataManager.predicate(forKeyPath: "gameId", exactValue: gameId)
        let predicateGCB = self.arfDataManager.predicate(forKeyPath: "gpOrder", exactValue: "\(order)")
        let predicateGCC = self.arfDataManager.predicate(forKeyPath: "gpIsDone", notValue: "1")
        let predicateGCD = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateGCA, predicateGCB, predicateGCC])
        
        guard let gameClue = self.arfDataManager.db.retrieveObject(forEntity: entityGameClue, filteredBy: predicateGCD) as? GameClue else {
            print("ERROR: Can't retrieve game clue object!")
            completion(nil)
            return
        }
        
        let result: [String: GameClue] = ["gameClue": gameClue]
        completion(result)
    }
    
    // MARK: - Locating Treasure
    
    func retrieveTreasure(atCurrentLocation location: CLLocation, forGameWithId gameId: String, completion: @escaping ARFLocationManagerGameTreasureBlock) {
        let entityGameTreasure = ARFConstants.entity.GAME_TREASURE
        let predicateGTA = self.arfDataManager.predicate(forKeyPath: "gameId", exactValue: gameId)
        let predicateGTB = self.arfDataManager.predicate(forKeyPath: "gpIsDone", notValue: "1")
        let predicateGTC = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateGTA, predicateGTB])
        
        guard let gameTreasure = self.arfDataManager.db.retrieveObject(forEntity: entityGameTreasure, filteredBy: predicateGTC) as? GameTreasure else {
            print("ERROR: Can't retrieve game treasure object!")
            completion(nil)
            return
        }
        
        let latitude = gameTreasure.latitude
        let longitude = gameTreasure.longitude
        let treasureLocation = CLLocation(latitude: latitude, longitude: longitude)
        let treasureInMeters = treasureLocation.distance(from: location)
        let distance = treasureInMeters / 1000
        
        print("TREASURE NAME: \(gameTreasure.name ?? "")")
        print("LATITUDE: \(latitude)")
        print("LONGITUDE: \(longitude)")
        print("DISTANCE: km: \(distance) m: \(treasureInMeters)")
        
        let treasure = treasureInMeters <= ARFConstants.gamePlay.RADIUS ? gameTreasure : nil
        completion(["gameTreasure": treasure])
    }
    
    func retrieveTreasure(forGameWithId gameId: String, completion: @escaping ARFLocationManagerGameTreasureBlock) {
        let entityGameTreasure = ARFConstants.entity.GAME_TREASURE
        let predicateGTA = self.arfDataManager.predicate(forKeyPath: "gameId", exactValue: gameId)
        let predicateGTB = self.arfDataManager.predicate(forKeyPath: "gpIsDone", notValue: "1")
        let predicateGTC = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateGTA, predicateGTB])
        
        guard let gameTreasure = self.arfDataManager.db.retrieveObject(forEntity: entityGameTreasure, filteredBy: predicateGTC) as? GameTreasure else {
            print("ERROR: Can't retrieve game treasure object!")
            completion(nil)
            return
        }
        
        completion(["gameTreasure": gameTreasure])
    }
    
    // MARK: - Google Map APIs
    
    func getPolylineRoute(from s: CLLocationCoordinate2D, to d: CLLocationCoordinate2D, completion: @escaping ARFLocationManagerDataBlock) {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let sLat = s.latitude, sLng = s.longitude, dLat = d.latitude, dLng = d.longitude
        let url = URL(string: "http://maps.googleapis.com/maps/api/directions/json?origin=\(sLat),\(sLng)&destination=\(dLat),\(dLng)&sensor=false&mode=walking")
        
        print("Google Map URL: \(String(describing: url))")
        
        if url != nil {
            let task = session.dataTask(with: url!, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    completion(nil)
                }
                else {
                    do {
                        if let json: [String: Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                            
                            guard let routes = json["routes"] as? [Any] else {
                                print("ERROR: Can't parse routes!")
                                completion(nil)
                                return
                            }
                            
                            print("Google Map Routes: \(routes)")
                            
                            if routes.count > 0 {
                                guard let overview_polyline = (routes[0] as? [String: Any])?["overview_polyline"] as? [String: Any] else {
                                    print("ERROR: Can't parse overview polyline!")
                                    completion(nil)
                                    return
                                }
                                
                                guard let points = overview_polyline["points"] as? String else {
                                    print("ERROR: Can't parse overview points!")
                                    completion(nil)
                                    return
                                }
                                
                                let result: [String: String] = ["points": points]
                                completion(result)
                            }
                            else {
                                print("ERROR: Empty routes!")
                                completion(nil)
                            }
                        }
                    }
                    catch{
                        print("ERROR: Can't serialize JSON!")
                        completion(nil)
                    }
                }
            })
            
            task.resume()
        }
        else {
            completion(nil)
        }
    }
    
    func getPolylineRoutes(from s: CLLocationCoordinate2D, to d: CLLocationCoordinate2D, completion: @escaping ARFLocationManagerDataBlock) {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let sLat = s.latitude, sLng = s.longitude, dLat = d.latitude, dLng = d.longitude
        let url = URL(string: "http://maps.googleapis.com/maps/api/directions/json?origin=\(sLat),\(sLng)&destination=\(dLat),\(dLng)&sensor=false&mode=walking")
        
        print("Google Map URL: \(String(describing: url))")
        
        if url != nil {
            let task = session.dataTask(with: url!, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    completion(nil)
                }
                else {
                    do {
                        if let json: [String: Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                            
                            guard let routes = json["routes"] as? [Any] else {
                                print("ERROR: Can't parse routes!")
                                completion(nil)
                                return
                            }
                            
                            print("Google Map Routes: \(routes)")
                            
                            if routes.count > 0 {
                                guard let legs = (routes[0] as? [String: Any])?["legs"] as? [[String: Any]] else {
                                    print("ERROR: Can't parse legs!")
                                    completion(nil)
                                    return
                                }
                                
                                if legs.count > 0 {
                                    var routes = [[String: Any]]()
                                    
                                    for leg in legs {
                                        if let steps = leg["steps"] as? [[String: Any]] {
                                            for step in steps {
                                                let maneuver = self.arfDataManager.string(step["maneuver"])
                                                
                                                if  let start_location = step["start_location"] as? [String: Double],
                                                    let end_location = step["end_location"] as? [String: Double] {
                                                    let start_location_lat = start_location["lat"] ?? 0.0
                                                    let start_location_lng = start_location["lng"] ?? 0.0
                                                    let end_location_lat = end_location["lat"] ?? 0.0
                                                    let end_location_lng = end_location["lng"] ?? 0.0
                                                    
                                                    let route: [String: Any] = ["start_location_lat": start_location_lat,
                                                                                "start_location_lng": start_location_lng,
                                                                                "end_location_lat": end_location_lat,
                                                                                "end_location_lng": end_location_lng,
                                                                                "maneuver": maneuver]
                                                    
                                                    routes.append(route)
                                                }
                                            }
                                        }
                                    }
                                    
                                    if routes.count > 0 {
                                        let data: [String: Any] = ["routes": routes]
                                        completion(data)
                                        return
                                    }
                                    else {
                                        print("ERROR: Assembled empty routes!")
                                        completion(nil)
                                        return
                                    }
                                }
                                else {
                                    print("ERROR: Retrieved empty steps!")
                                    completion(nil)
                                    return
                                }
                            }
                            else {
                                print("ERROR: Empty routes!")
                                completion(nil)
                            }
                        }
                    }
                    catch{
                        print("ERROR: Can't serialize JSON!")
                        completion(nil)
                    }
                }
            })
            
            task.resume()
        }
        else {
            completion(nil)
        }
    }
    
}
