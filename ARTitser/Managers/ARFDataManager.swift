//
//  ARFDataManager.swift
//  ARFollow
//
//  Created by Julius Abarra on 12/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import Foundation
import CoreData

class ARFDataManager: ARFRoutes {
    
    // MARK: - Singleton
    
    static let sharedInstance: ARFDataManager = {
        return ARFDataManager()
    }()
    
    // MARK: - Properties
    
    let db = ARFCoreDataStack(name: "ARFDataModel")
    var dateFormatter: DateFormatter = DateFormatter()
    var userDefaults: UserDefaults = UserDefaults.standard
    
    var loggedUserId: Int64 = 0
    var loggedUserFirstName: String = ""
    var loggedUserFullName: String = ""
    var loggedUserType: Int64 = 0
    var loggedClassId: Int64 = 0
    
    fileprivate let session = URLSession.shared
    
    typealias ARFDMDoneBlock = (_ doneBlock: Bool) -> Void
    typealias ARFDMDataBlock = (_ dataBlock: [String: Any]?) -> Void
    
    var serverUrl = "http://localhost:8080"
    
    // MARK: - API Requests
    
    /// Requests server for user authentication.
    ///
    /// - parameters:
    ///     - un: A String identifying username
    ///     - pw: A String identifying password
    func requestLoginUser(withUsername un: String, andPassword pw: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.PRI_LOGIN_USER)")
        let body = ["username": un, "password": pw] as AnyObject
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body) else {
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                let result: [String: Any] = ["status": 1, "message": "\(error!.localizedDescription)"]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let responseData = json["data"] as? [String: Any], let user = responseData["user"] as? [String: Any] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let dataBlock: [String: Any] = ["status": 1, "message": message]
                    completion(dataBlock)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.USER])
                
                if cleared {
                    ctx.performAndWait {
                        let id = self.intString(self.string(user["id"]))
                        let lastName = self.string(user["lastName"])
                        let firstName = self.string(user["firstName"])
                        let middleName = self.string(user["middleName"])
                        let gender = self.intString(self.string(user["gender"]))
                        let birthdate = self.string(user["birthdate"])
                        let address = self.string(user["address"])
                        let mobile = self.string(user["mobile"])
                        let email = self.string(user["email"])
                        let type = self.intString(self.string(user["type"]))
                        let username = self.string(user["username"])
                        let encryptedUsername = self.string(user["encryptedUsername"])
                        let password = self.string(user["password"])
                        let encryptedPassword = self.string(user["encryptedPassword"])
                        let owner = self.intString(self.string(user["owner"]))
                        let dateCreated = self.string(user["dateCreated"])
                        let dateUpdated = self.string(user["dateUpdated"])
                        let imageUrl = self.string(user["imageUrl"])
                        
                        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                        let user = self.db.retrieveEntity(ARFConstants.entity.USER, fromContext: ctx, filteredBy: predicate) as! User
                        
                        user.id = id
                        user.lastName = lastName
                        user.firstName = firstName
                        user.middleName = middleName
                        user.gender = gender
                        user.birthdate = birthdate
                        user.address = address
                        user.mobile = mobile
                        user.email = email
                        user.type = type
                        user.username = username
                        user.encryptedUsername = encryptedUsername
                        user.password = password
                        user.encryptedPassword = encryptedPassword
                        user.owner = owner
                        user.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                        user.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                        user.imageUrl = "\(self.serverUrl)/\(imageUrl)"
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            self.loggedUserId = id
                            self.loggedUserFirstName = firstName
                            self.loggedUserType = type
                            self.loggedUserFullName = middleName == "" ? "\(firstName) \(lastName)" : "\(firstName) \(middleName) \(lastName)"
                            
                            let result: [String: Any] = ["status": 0, "message": rMessage]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save user's details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear user entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Logs user from the system
    ///
    /// - parameters:
    ///     - userId    : A String identifying user's id
    ///     - completion: A completion handler
    func requestLogoutUser(withId userId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.PRI_LOGOUT_USER)", userId)
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let user = rd["user"] as? [String: Any] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let result: [String: Any] = ["status": 0, "message": rMessage, "user": user]
                completion(result)
                return
                
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Requests server to create a new user.
    ///
    /// - parameters:
    ///     - body      : A Dictionary identifying data to be created
    ///     - imageKey  : A String identifying attribute name for the image
    ///     - imageData : A Data identifying user's image
    ///     - completion: A completion handler
    func requestCreateUser(withBody body: [String: Any], imageKey: String, andImageData imageData: Data?, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.USR_CREATE_USER)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        var urlRequest: URLRequest? = nil
        
        if imageData != nil { urlRequest = self.route(uri, withParameters: body, imageKey: imageKey, andImageData: imageData!) }
        else { urlRequest = self.route(uri, withBody: body as AnyObject) }
        
        guard let request = urlRequest else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Retrieves users from the server.
    ///
    /// - parameter completion: A completion handler
    func requestRetrieveUsers(_ completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.USR_RETRIEVE_USERS)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let users = rd["users"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.USER])
                
                if cleared {
                    ctx.performAndWait {
                        for user in users {
                            let id = self.intString(self.string(user["id"]))
                            let lastName = self.string(user["lastName"])
                            let firstName = self.string(user["firstName"])
                            let middleName = self.string(user["middleName"])
                            let gender = self.intString(self.string(user["gender"]))
                            let birthdate = self.string(user["birthdate"])
                            let address = self.string(user["address"])
                            let mobile = self.string(user["mobile"])
                            let email = self.string(user["email"])
                            let type = self.intString(self.string(user["type"]))
                            let username = self.string(user["username"])
                            let encryptedUsername = self.string(user["encryptedUsername"])
                            let password = self.string(user["password"])
                            let encryptedPassword = self.string(user["encryptedPassword"])
                            let owner = self.intString(self.string(user["owner"]))
                            let dateCreated = self.string(user["dateCreated"])
                            let dateUpdated = self.string(user["dateUpdated"])
                            let imageUrl = self.string(user["imageUrl"])
                            let isForApproval = self.string(user["isForApproval"])
                            let searchString = "\(id)\(lastName)\(firstName)\(middleName)"
                            
                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let aUser = self.db.retrieveEntity(ARFConstants.entity.USER, fromContext: ctx, filteredBy: predicate) as! User
                            
                            aUser.id = id
                            aUser.lastName = lastName
                            aUser.firstName = firstName
                            aUser.middleName = middleName
                            aUser.gender = gender
                            aUser.birthdate = birthdate
                            aUser.address = address
                            aUser.mobile = mobile
                            aUser.email = email
                            aUser.type = type
                            aUser.username = username
                            aUser.encryptedUsername = encryptedUsername
                            aUser.password = password
                            aUser.encryptedPassword = encryptedPassword
                            aUser.owner = owner
                            aUser.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                            aUser.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                            aUser.imageUrl = "\(self.serverUrl)/\(imageUrl)"
                            aUser.isForApproval = isForApproval
                            aUser.searchString = searchString
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": users.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save user's details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear user entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Requests server to update an existing user.
    ///
    /// - parameters:
    ///     - id        : A String identifying user's id
    ///     - body      : A Dictionary identifying data to be updated
    ///     - imageKey  : A String identifying attribute name for the image
    ///     - imageData : A Data identifying user's image
    ///     - completion: A completion handler
    func requestUpdateUser(withId id: String, body: [String: Any], imageKey: String, andImageData imageData: Data?, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.USR_UPDATE_USER_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        var urlRequest: URLRequest? = nil
        
        if imageData != nil { urlRequest = self.route(uri, withParameters: body, imageKey: imageKey, andImageData: imageData!) }
        else { urlRequest = self.route(uri, withBody: body as AnyObject) }
        
        guard let request = urlRequest else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to delete a user.
    ///
    /// - parameters:
    ///     - id        : A String identifying user's id
    ///     - completion: A completion handler
    func requestDeleteUser(withId id: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.USR_DELETE_USER_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "POST", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to approve user registration.
    ///
    /// - parameters:
    ///     - id        : A String identifying user's id
    ///     - body      : A Dictionary identifying data to be updated
    ///     - completion: A completion handler
    func requestApproveUser(withId id: String, body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.USR_APPROVE_USER_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to create a new course.
    ///
    /// - parameters:
    ///     - body      : A Dictionary identifying data to be created
    ///     - completion: A completion handler
    func requestCreateCourse(withBody body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CRS_CREATE_COURSE)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Retrieves courses from the server.
    ///
    /// - parameter completion: A completion handler
    func requestRetrieveCourses(_ completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CRS_RETRIEVE_COURSES)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let courses = rd["courses"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.COURSE])
                
                if cleared {
                    ctx.performAndWait {
                        for course in courses {
                            let id = self.intString(self.string(course["id"]))
                            let code = self.string(course["code"])
                            let title = self.string(course["title"])
                            let courseDescription = self.string(course["courseDescription"])
                            let unit = self.intString(self.string(course["unit"]))
                            let owner = self.intString(self.string(course["owner"]))
                            let dateCreated = self.string(course["dateCreated"])
                            let dateUpdated = self.string(course["dateUpdated"])
                            let searchString = "\(code)\(title)\(courseDescription)"
                            
                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let aCourse = self.db.retrieveEntity(ARFConstants.entity.COURSE, fromContext: ctx, filteredBy: predicate) as! Course
                            
                            aCourse.id = id
                            aCourse.code = code
                            aCourse.title = title
                            aCourse.courseDescription = courseDescription
                            aCourse.unit = unit
                            aCourse.owner = owner
                            aCourse.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                            aCourse.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                            aCourse.searchString = searchString
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": courses.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save course's details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear course entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Requests server to update an existing course.
    ///
    /// - parameters:
    ///     - id        : A String identifying course's id
    ///     - body      : A Dictionary identifying data to be updated
    ///     - completion: A completion handler
    func requestUpdateCourse(withId id: String, body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CRS_UPDATE_COURSE_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to delete a course.
    ///
    /// - parameters:
    ///     - id        : A String identifying course's id
    ///     - completion: A completion handler
    func requestDeleteCourse(withId id: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CRS_DELETE_COURSE_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "POST", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to create a new class.
    ///
    /// - parameters:
    ///     - body      : A Dictionary identifying data to be created
    ///     - completion: A completion handler
    func requestCreateClass(withBody body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CLS_CREATE_CLASS)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Retrieves classes created by user from the server.
    ///
    /// - parameters:
    ///     - completion: A completion handler
    func requestRetrieveClasses(_ completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CLS_RETRIEVE_CLASSES)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let classes = rd["classes"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.CLASS,
                                                     ARFConstants.entity.CLASS_COURSE,
                                                     ARFConstants.entity.CLASS_CREATOR,
                                                     ARFConstants.entity.CLASS_PLAYER])
                
                if cleared {
                    ctx.performAndWait {
                        for c in classes {
                            let id = self.intString(self.string(c["id"]))
                            let code = self.string(c["code"])
                            let aClassDescription = self.string(c["aClassDescription"])
                            let schedule = self.string(c["schedule"])
                            let venue = self.string(c["venue"])
                            let owner = self.intString(self.string(c["owner"]))
                            let dateCreated = self.string(c["dateCreated"])
                            let dateUpdated = self.string(c["dateUpdated"])
                            let searchString = "\(code)\(aClassDescription)"
                            
                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let klase = self.db.retrieveEntity(ARFConstants.entity.CLASS, fromContext: ctx, filteredBy: predicate) as! Class
                            
                            klase.id = id
                            klase.code = code
                            klase.aClassDescription = aClassDescription
                            klase.schedule = schedule
                            klase.venue = venue
                            klase.owner = owner
                            klase.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                            klase.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                            klase.searchString = searchString
                            klase.creatorId = 0
                            
                            // Course
                            if let course = c["course"] as? [String: Any] {
                                self.relateCourse(course, toClass: klase)
                            }
                            
                            // Creator
                            if let creator = c["creator"] as? [String: Any] {
                                self.relateCreator(creator, toClass: klase)
                            }
                            
                            // Players
                            if let players = c["players"] as? [[String: Any]] {
                                self.relatePlayers(players, toClass: klase)
                            }
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": classes.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save class' details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear class entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Retrieves classes where a player is enrolled to
    /// from the server.
    ///
    /// - parameters:
    ///     - playerId  : A String identifying player's id
    ///     - completion: A completion handler
    func requestRetrieveClasses(forPlayerWithId playerId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CLS_RETRIEVE_CLASSES_FOR_PLAYER)", playerId, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let classes = rd["classes"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.CLASS,
                                                     ARFConstants.entity.CLASS_COURSE,
                                                     ARFConstants.entity.CLASS_CREATOR,
                                                     ARFConstants.entity.CLASS_PLAYER])
                
                if cleared {
                    ctx.performAndWait {
                        for c in classes {
                            let id = self.intString(self.string(c["id"]))
                            let code = self.string(c["code"])
                            let aClassDescription = self.string(c["aClassDescription"])
                            let schedule = self.string(c["schedule"])
                            let venue = self.string(c["venue"])
                            let owner = self.intString(self.string(c["owner"]))
                            let dateCreated = self.string(c["dateCreated"])
                            let dateUpdated = self.string(c["dateUpdated"])
                            let searchString = "\(code)\(aClassDescription)"
                            
                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let klase = self.db.retrieveEntity(ARFConstants.entity.CLASS, fromContext: ctx, filteredBy: predicate) as! Class
                            
                            klase.id = id
                            klase.code = code
                            klase.aClassDescription = aClassDescription
                            klase.schedule = schedule
                            klase.venue = venue
                            klase.owner = owner
                            klase.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                            klase.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                            klase.searchString = searchString
                            klase.creatorId = 0
                            
                            // Save class id in singleton
                            self.loggedClassId = id
                            
                            // Course
                            if let course = c["course"] as? [String: Any] {
                                self.relateCourse(course, toClass: klase)
                            }
                            
                            // Creator
                            if let creator = c["creator"] as? [String: Any] {
                                self.relateCreator(creator, toClass: klase)
                            }
                            
                            // Players
                            if let players = c["players"] as? [[String: Any]] {
                                self.relatePlayers(players, toClass: klase)
                            }
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": classes.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save class' details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear class entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Attaches course to a class.
    ///
    /// - parameters:
    ///     - course: A Dictionary identifying course details
    ///     - klase : A Class object
    fileprivate func relateCourse(_ course: [String: Any], toClass klase: Class) {
        self.prettyFunction()
        
        guard let ctx = klase.managedObjectContext else {
            print("ERROR: Can't retrieve class context!")
            return
        }
        
        let id = self.intString(self.string(course["id"]))
        let code = self.string(course["code"])
        let title = self.string(course["title"])
        let courseDescription = self.string(course["courseDescription"])
        let unit = self.intString(self.string(course["unit"]))
        let owner = self.intString(self.string(course["owner"]))
        let dateCreated = self.string(course["dateCreated"])
        let dateUpdated = self.string(course["dateUpdated"])
        
        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
        let classCourse = self.db.retrieveEntity(ARFConstants.entity.CLASS_COURSE, fromContext: ctx, filteredBy: predicate) as! ClassCourse
        
        classCourse.id = id
        classCourse.code = code
        classCourse.title = title
        classCourse.courseDescription = courseDescription
        classCourse.unit = unit
        classCourse.owner = owner
        classCourse.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
        classCourse.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
        classCourse.classId = klase.id
        
        klase.courseCode = code
        klase.course = classCourse
    }
    
    /// Attaches creator to a class.
    ///
    /// - parameters:
    ///     - creator   : A Dictionary identifying creator details
    ///     - klase     : A Class object
    fileprivate func relateCreator(_ creator: [String: Any], toClass klase: Class) {
        self.prettyFunction()
        
        guard let ctx = klase.managedObjectContext else {
            print("ERROR: Can't retrieve class context!")
            return
        }
        
        let id = self.intString(self.string(creator["id"]))
        let lastName = self.string(creator["lastName"])
        let firstName = self.string(creator["firstName"])
        let middleName = self.string(creator["middleName"])
        let gender = self.intString(self.string(creator["gender"]))
        let birthdate = self.string(creator["birthdate"])
        let address = self.string(creator["address"])
        let mobile = self.string(creator["mobile"])
        let email = self.string(creator["email"])
        let type = self.intString(self.string(creator["type"]))
        let username = self.string(creator["username"])
        let encryptedUsername = self.string(creator["encryptedUsername"])
        let password = self.string(creator["password"])
        let encryptedPassword = self.string(creator["encryptedPassword"])
        let owner = self.intString(self.string(creator["owner"]))
        let dateCreated = self.string(creator["dateCreated"])
        let dateUpdated = self.string(creator["dateUpdated"])
        let imageUrl = self.string(creator["imageUrl"])
        
        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
        let classCreator = self.db.retrieveEntity(ARFConstants.entity.CLASS_CREATOR, fromContext: ctx, filteredBy: predicate) as! ClassCreator
        
        classCreator.id = id
        classCreator.lastName = lastName
        classCreator.firstName = firstName
        classCreator.middleName = middleName
        classCreator.gender = gender
        classCreator.birthdate = birthdate
        classCreator.address = address
        classCreator.mobile = mobile
        classCreator.email = email
        classCreator.type = type
        classCreator.username = username
        classCreator.encryptedUsername = encryptedUsername
        classCreator.password = password
        classCreator.encryptedPassword = encryptedPassword
        classCreator.owner = owner
        classCreator.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
        classCreator.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
        classCreator.imageUrl = "\(self.serverUrl)/\(imageUrl)"
        classCreator.classId = klase.id
        
        klase.creatorName = middleName == "" ? "\(firstName) \(lastName)" : "\(firstName) \(middleName) \(lastName)"
        klase.creator = classCreator
        klase.creatorId = id
    }
    
    /// Attaches players to a class.
    ///
    /// - parameters:
    ///     - players   : A Dictionary identifying array of players
    ///     - klase     : A Class object
    fileprivate func relatePlayers(_ players: [[String: Any]], toClass klase: Class) {
        self.prettyFunction()
        
        guard let ctx = klase.managedObjectContext else {
            print("ERROR: Can't retrieve class context!")
            return
        }
        
        var playerNames = ""
        
        for p in players {
            let id = self.intString(self.string(p["id"]))
            let lastName = self.string(p["lastName"])
            let firstName = self.string(p["firstName"])
            let middleName = self.string(p["middleName"])
            let gender = self.intString(self.string(p["gender"]))
            let birthdate = self.string(p["birthdate"])
            let address = self.string(p["address"])
            let mobile = self.string(p["mobile"])
            let email = self.string(p["email"])
            let type = self.intString(self.string(p["type"]))
            let username = self.string(p["username"])
            let encryptedUsername = self.string(p["encryptedUsername"])
            let password = self.string(p["password"])
            let encryptedPassword = self.string(p["encryptedPassword"])
            let owner = self.intString(self.string(p["owner"]))
            let dateCreated = self.string(p["dateCreated"])
            let dateUpdated = self.string(p["dateUpdated"])
            let imageUrl = self.string(p["imageUrl"])
            
            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
            let classPlayer = self.db.retrieveEntity(ARFConstants.entity.CLASS_PLAYER, fromContext: ctx, filteredBy: predicate) as! ClassPlayer
            
            classPlayer.id = id
            classPlayer.lastName = lastName
            classPlayer.firstName = firstName
            classPlayer.middleName = middleName
            classPlayer.gender = gender
            classPlayer.birthdate = birthdate
            classPlayer.address = address
            classPlayer.mobile = mobile
            classPlayer.email = email
            classPlayer.type = type
            classPlayer.username = username
            classPlayer.encryptedUsername = encryptedUsername
            classPlayer.password = password
            classPlayer.encryptedPassword = encryptedPassword
            classPlayer.owner = owner
            classPlayer.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
            classPlayer.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
            classPlayer.imageUrl = "\(self.serverUrl)/\(imageUrl)"
            classPlayer.classId = klase.id
            
            let playerName = middleName == "" ? "\(firstName) \(lastName)" : "\(firstName) \(middleName) \(lastName)"
            playerNames = "\(playerNames == "" ? "" : "\(playerNames), ")\(playerName)"
            klase.addToPlayers(classPlayer)
        }
        
        klase.playerNames = playerNames
    }
    
    /// Requests server to update an existing class.
    ///
    /// - parameters:
    ///     - id        : A String identifying class id
    ///     - body      : A Dictionary identifying data to be updated
    ///     - completion: A completion handler
    func requestUpdateClass(withId id: String, body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CLS_UPDATE_CLASS_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to delete a class.
    ///
    /// - parameters:
    ///     - id        : A String identifying class id
    ///     - completion: A completion handler
    func requestDeleteClass(withId id: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CLS_DELETE_CLASS_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "POST", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to create a new clue.
    ///
    /// - parameters:
    ///     - body      : A Dictionary identifying data to be created
    ///     - completion: A completion handler
    func requestCreateClue(withBody body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CLU_CREATE_CLUE)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Retrieves clues created by user from the server.
    ///
    /// - parameters:
    ///     - userId    : A String identifying user id
    ///     - completion: A completion handler
    func requestRetrieveClues(forUserWithId userId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CLU_RETRIEVE_CLUES_CREATED_BY_USER)", userId, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let clues = rd["clues"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.CLUE, ARFConstants.entity.CLUE_CHOICE])
                
                if cleared {
                    ctx.performAndWait {
                        for c in clues {
                            let id = self.intString(self.string(c["id"]))
                            let type = self.intString(self.string(c["type"]))
                            let riddle = self.string(c["riddle"])
                            let longitude = self.doubleString(self.string(c["longitude"]))
                            let latitude = self.doubleString(self.string(c["latitude"]))
                            let locationName = self.string(c["locationName"])
                            let points = self.intString(self.string(c["points"]))
                            let pointsOnAttempts = self.string(c["pointsOnAttempts"])
                            let clue = self.string(c["clue"])
                            let owner = self.intString(self.string(c["owner"]))
                            let dateCreated = self.string(c["dateCreated"])
                            let dateUpdated = self.string(c["dateUpdated"])
                            let searchString = "\(id)\(riddle)\(clue)"
                            
                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let aClue = self.db.retrieveEntity(ARFConstants.entity.CLUE, fromContext: ctx, filteredBy: predicate) as! Clue
                            
                            aClue.id = id
                            aClue.type = type
                            aClue.riddle = riddle
                            aClue.longitude = longitude
                            aClue.latitude = latitude
                            aClue.locationName = locationName
                            aClue.points = points
                            aClue.pointsOnAttempts = pointsOnAttempts
                            aClue.clue = clue
                            aClue.owner = owner
                            aClue.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                            aClue.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                            aClue.searchString = searchString
                            
                            // Choices
                            if let choices = c["choices"] as? [[String: Any]] {
                                self.relateChoices(choices, toClue: aClue)
                            }
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": clues.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save clue's details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear clue entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Attaches choices to a clue.
    ///
    /// - parameters:
    ///     - choices   : A Dictionary identifying array of choices
    ///     - clue      : A Clue object
    fileprivate func relateChoices(_ choices: [[String: Any]], toClue clue: Clue) {
        self.prettyFunction()
        
        guard let ctx = clue.managedObjectContext else {
            print("ERROR: Can't retrieve clue context!")
            return
        }
        
        for choice in choices {
            let id = self.intString(self.string(choice["id"]))
            let clueId = self.intString(self.string(choice["clueId"]))
            let choiceStatement = self.string(choice["choiceStatement"])
            let isCorrect = self.intString(self.string(choice["isCorrect"]))
            let answer = self.string(choice["answer"])
            let encryptedAnswer = self.string(choice["encryptedAnswer"])
            let isCaseSensitive = self.intString(self.string(choice["isCaseSensitive"]))
            let dateCreated = self.string(choice["dateCreated"])
            let dateUpdated = self.string(choice["dateUpdated"])
            
            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
            let aChoice = self.db.retrieveEntity(ARFConstants.entity.CLUE_CHOICE, fromContext: ctx, filteredBy: predicate) as! ClueChoice
            
            aChoice.id = id
            aChoice.clueId = clueId
            aChoice.choiceStatement = choiceStatement
            aChoice.isCorrect = isCorrect
            aChoice.answer = answer
            aChoice.encryptedAnswer = encryptedAnswer
            aChoice.isCaseSensitive = isCaseSensitive
            aChoice.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
            aChoice.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
            
            clue.addToChoices(aChoice)
        }
    }
    
    /// Requests server to update an existing clue.
    ///
    /// - parameters:
    ///     - id        : A String identifying clue's id
    ///     - body      : A Dictionary identifying data to be updated
    ///     - completion: A completion handler
    func requestUpdateClue(withId id: String, body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CLU_UPDATE_CLUE_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to delete a clue.
    ///
    /// - parameters:
    ///     - id        : A String identifying clue id
    ///     - completion: A completion handler
    func requestDeleteClue(withId id: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.CLU_DELETE_CLUE_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "POST", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to create a new treasure.
    ///
    /// - parameters:
    ///     - body          : A Dictionary identifying data to be created
    ///     - imageKey      : A String identifying attribute name for the image
    ///     - imageData     : A Data identifying treasure's image
    ///     - model3dKey    : A String identifying attribute name for the 3d model
    ///     - model3dData   : A Data identifying treasure's 3d model
    ///     - completion    : A completion handler
    func requestCreateTreasure(withBody body: [String: Any], imageKey: String, imageData: Data?, model3dKey: String, andModel3dData model3dData: Data?, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.TRE_CREATE_TREASURE)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        var urlRequest: URLRequest? = nil
        
        if imageData != nil && model3dData != nil { urlRequest = self.route(uri, withParameters: body, imageKey: imageKey, imageData: imageData!, model3dKey: model3dKey, andModel3dData: model3dData!) }
        else if imageData != nil { urlRequest = self.route(uri, withParameters: body, imageKey: imageKey, andImageData: imageData!) }
        else { urlRequest = self.route(uri, withBody: body as AnyObject) }
        
        guard let request = urlRequest else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Retrieves treasures created by user from the server.
    ///
    /// - parameters:
    ///     - id        : A String identifying user id
    ///     - completion: A completion handler
    func requestRetrieveTreasures(forUserWithId id: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.TRE_RETRIEVE_TREASURES_CREATED_USER)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let treasures = rd["treasures"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.TREASURE])
                
                if cleared {
                    ctx.performAndWait {
                        for treasure in treasures {
                            let id = self.intString(self.string(treasure["id"]))
                            let name = self.string(treasure["name"])
                            let treasureDescription = self.string(treasure["treasureDescription"])
                            let imageUrl = self.string(treasure["imageUrl"])
                            let imageLocalName = self.string(treasure["imageLocalName"])
                            let model3dUrl = self.string(treasure["model3dUrl"])
                            let model3dLocalName = self.string(treasure["model3dLocalName"])
                            let claimingQuestion = self.string(treasure["claimingQuestion"])
                            let claimingAnswers = self.string(treasure["claimingAnswers"])
                            let encryptedClaimingAnswers = self.string(treasure["encryptedClaimingAnswers"])
                            let isCaseSensitive = self.intString(self.string(treasure["isCaseSensitive"]))
                            let longitude = self.doubleString(self.string(treasure["longitude"]))
                            let latitude = self.doubleString(self.string(treasure["latitude"]))
                            let locationName = self.string(treasure["locationName"])
                            let points = self.intString(self.string(treasure["points"]))
                            let owner = self.intString(self.string(treasure["owner"]))
                            let dateCreated = self.string(treasure["dateCreated"])
                            let dateUpdated = self.string(treasure["dateUpdated"])
                            let searchString = "\(id)\(name)\(treasureDescription)"
                            
                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let aTreasure = self.db.retrieveEntity(ARFConstants.entity.TREASURE, fromContext: ctx, filteredBy: predicate) as! Treasure
                            
                            aTreasure.id = id
                            aTreasure.name = name
                            aTreasure.treasureDescription = treasureDescription
                            aTreasure.imageUrl = "\(self.serverUrl)/\(imageUrl)"
                            aTreasure.imageLocalName = imageLocalName
                            aTreasure.model3dUrl = "\(self.serverUrl)/\(model3dUrl)"
                            aTreasure.model3dLocalName = model3dLocalName
                            aTreasure.claimingQuestion = claimingQuestion
                            aTreasure.claimingAnswers = claimingAnswers
                            aTreasure.encryptedClaimingAnswers = encryptedClaimingAnswers
                            aTreasure.isCaseSensitive = isCaseSensitive
                            aTreasure.longitude = longitude
                            aTreasure.latitude = latitude
                            aTreasure.locationName = locationName
                            aTreasure.points = points
                            aTreasure.owner = owner
                            aTreasure.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                            aTreasure.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                            aTreasure.searchString = searchString
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": treasures.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save treasure's details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear treasure entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Requests server to update treasure.
    ///
    /// - parameters:
    ///     - id            : A String identifying treasure's id
    ///     - body          : A Dictionary identifying data to be created
    ///     - imageKey      : A String identifying attribute name for the image
    ///     - imageData     : A Data identifying treasure's image
    ///     - model3dKey    : A String identifying attribute name for the 3d model
    ///     - model3dData   : A Data identifying treasure's 3d model
    ///     - completion    : A completion handler
    func requestUpdateTreasure(withId id: String, body: [String: Any], imageKey: String, imageData: Data?, model3dKey: String, andModel3dData model3dData: Data?, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.TRE_UPDATE_TREASURE_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        var urlRequest: URLRequest? = nil
        
        if imageData != nil && model3dData != nil { urlRequest = self.route(uri, withParameters: body, imageKey: imageKey, imageData: imageData!, model3dKey: model3dKey, andModel3dData: model3dData!) }
        else if imageData != nil { urlRequest = self.route(uri, withParameters: body, imageKey: imageKey, andImageData: imageData!) }
        else { urlRequest = self.route(uri, withBody: body as AnyObject) }
        
        guard let request = urlRequest else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to delete a treasure.
    ///
    /// - parameters:
    ///     - id        : A String identifying treasure's id
    ///     - completion: A completion handler
    func requestDeleteTreasure(withId id: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.TRE_DELETE_TREASURE_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "POST", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to create a new game.
    ///
    /// - parameters:
    ///     - body      : A Dictionary identifying data to be created
    ///     - completion: A completion handler
    func requestCreateGame(withBody body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_CREATE_GAME)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Retrieves games created by user from the server.
    ///
    /// - parameters:
    ///     - id        : A String identifying user id
    ///     - completion: A completion handler
    func requestRetrieveGames(forUserWithId id: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_RETRIEVE_GAMES_CREATED_BY_USER)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let games = rd["games"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.GAME,
                                                     ARFConstants.entity.GAME_TREASURE,
                                                     ARFConstants.entity.GAME_CLUE,
                                                     ARFConstants.entity.GAME_CLUE_CHOICE])
                
                if cleared {
                    ctx.performAndWait {
                        for game in games {
                            let id = self.intString(self.string(game["id"]))
                            let name = self.string(game["name"])
                            let discussion = self.string(game["discussion"])
                            let isTimeBound = self.intString(self.string(game["isTimeBound"]))
                            let minutes = self.intString(self.string(game["minutes"]))
                            let isNoExpiration = self.intString(self.string(game["isNoExpiration"]))
                            let start = self.string(game["start"])
                            let end = self.string(game["end"])
                            let isSecure = self.intString(self.string(game["isSecure"]))
                            let securityCode = self.string(game["securityCode"])
                            let encryptedSecurityCode = self.string(game["encryptedSecurityCode"])
                            let startingClueId = self.intString(self.string(game["startingClueId"]))
                            let startingClueName = self.string(game["startingClueName"])
                            let owner = self.intString(self.string(game["owner"]))
                            let dateCreated = self.string(game["dateCreated"])
                            let dateUpdated = self.string(game["dateUpdated"])
                            let searchString = "\(id)\(name)\(discussion)"
                            
                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let aGame = self.db.retrieveEntity(ARFConstants.entity.GAME, fromContext: ctx, filteredBy: predicate) as! Game
                            
                            let defaultStartDate = self.date(fromString: "\(Date())", format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                            let startDate = self.date(fromString: start, format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                            let defaultEndDate = self.addDays(1, toDate: defaultStartDate)
                            let endDate = self.date(fromString: end, format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                            
                            aGame.id = id
                            aGame.name = name
                            aGame.discussion = discussion
                            aGame.totalPoints = 0
                            aGame.isTimeBound = isTimeBound
                            aGame.minutes = minutes
                            aGame.isNoExpiration = isNoExpiration
                            aGame.start = start == "" ? defaultStartDate : startDate
                            aGame.end = end == "" ? defaultEndDate : endDate
                            aGame.isSecure = isSecure
                            aGame.securityCode = securityCode
                            aGame.encryptedSecurityCode = encryptedSecurityCode
                            aGame.startingClueId = startingClueId
                            aGame.startingClueName = startingClueName
                            aGame.owner = owner
                            aGame.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                            aGame.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                            aGame.searchString = searchString
                            
                            // Treasure
                            if let treasure = game["treasure"] as? [String: Any] {
                                self.relateTreasure(treasure, toGame: aGame)
                            }
                            
                            // Clues
                            if let clues = game["clues"] as? [[String: Any]] {
                                self.relateClues(clues, toGame: aGame)
                            }
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": games.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save game's details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear game entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Retrieves games associated to a class from the server.
    ///
    /// - parameters:
    ///     - id        : A String identifying class id
    ///     - completion: A completion handler
    func requestRetrieveGames(forClassWithId id: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_RETRIEVE_GAMES_FOR_CLASS)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let games = rd["games"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.GAME,
                                                     ARFConstants.entity.GAME_TREASURE,
                                                     ARFConstants.entity.GAME_CLUE,
                                                     ARFConstants.entity.GAME_CLUE_CHOICE])
                
                if cleared {
                    ctx.performAndWait {
                        for game in games {
                            let id = self.intString(self.string(game["id"]))
                            let name = self.string(game["name"])
                            let discussion = self.string(game["discussion"])
                            let isTimeBound = self.intString(self.string(game["isTimeBound"]))
                            let minutes = self.intString(self.string(game["minutes"]))
                            let isNoExpiration = self.intString(self.string(game["isNoExpiration"]))
                            let start = self.string(game["start"])
                            let end = self.string(game["end"])
                            let isSecure = self.intString(self.string(game["isSecure"]))
                            let securityCode = self.string(game["securityCode"])
                            let encryptedSecurityCode = self.string(game["encryptedSecurityCode"])
                            let startingClueId = self.intString(self.string(game["startingClueId"]))
                            let startingClueName = self.string(game["startingClueName"])
                            let owner = self.intString(self.string(game["owner"]))
                            let dateCreated = self.string(game["dateCreated"])
                            let dateUpdated = self.string(game["dateUpdated"])
                            let searchString = "\(id)\(name)\(discussion)"
                            
                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let aGame = self.db.retrieveEntity(ARFConstants.entity.GAME, fromContext: ctx, filteredBy: predicate) as! Game
                            
                            let defaultStartDate = self.date(fromString: "\(Date())", format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                            let startDate = self.date(fromString: start, format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                            let defaultEndDate = self.addDays(1, toDate: defaultStartDate)
                            let endDate = self.date(fromString: end, format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                            
                            aGame.id = id
                            aGame.name = name
                            aGame.discussion = discussion
                            aGame.totalPoints = 0
                            aGame.isTimeBound = isTimeBound
                            aGame.minutes = minutes
                            aGame.isNoExpiration = isNoExpiration
                            aGame.start = start == "" ? defaultStartDate : startDate
                            aGame.end = end == "" ? defaultEndDate : endDate
                            aGame.isSecure = isSecure
                            aGame.securityCode = securityCode
                            aGame.encryptedSecurityCode = encryptedSecurityCode
                            aGame.startingClueId = startingClueId
                            aGame.startingClueName = startingClueName
                            aGame.owner = owner
                            aGame.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                            aGame.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                            aGame.searchString = searchString
                            
                            // Treasure
                            if let treasure = game["treasure"] as? [String: Any] {
                                self.relateTreasure(treasure, toGame: aGame)
                            }
                            
                            // Clues
                            if let clues = game["clues"] as? [[String: Any]] {
                                self.relateClues(clues, toGame: aGame)
                            }
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": games.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save game's details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear game entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Requests server to update an existing game.
    ///
    /// - parameters:
    ///     - id        : A String identifying game's id
    ///     - body      : A Dictionary identifying data to be updated
    ///     - completion: A completion handler
    func requestUpdateGame(withId id: String, body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_UPDATE_GAME_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to delete a game.
    ///
    /// - parameters:
    ///     - id        : A String identifying game's id
    ///     - completion: A completion handler
    func requestDeleteGame(withId id: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_DELETE_GAME_BY_ID)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "POST", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Attaches treasure to a game.
    ///
    /// - parameters:
    ///     - treasure  : A Dictionary identifying treasure details
    ///     - game      : A Game object
    fileprivate func relateTreasure(_ treasure: [String: Any], toGame game: Game) {
        self.prettyFunction()
        
        guard let ctx = game.managedObjectContext else {
            print("ERROR: Can't retrieve game context!")
            return
        }
        
        let id = self.intString(self.string(treasure["id"]))
        let name = self.string(treasure["name"])
        let treasureDescription = self.string(treasure["treasureDescription"])
        let imageUrl = self.string(treasure["imageUrl"])
        let imageLocalName = self.string(treasure["imageLocalName"])
        let model3dUrl = self.string(treasure["model3dUrl"])
        let model3dLocalName = self.string(treasure["model3dLocalName"])
        let claimingQuestion = self.string(treasure["claimingQuestion"])
        let claimingAnswers = self.string(treasure["claimingAnswers"])
        let encryptedClaimingAnswers = self.string(treasure["encryptedClaimingAnswers"])
        let isCaseSensitive = self.intString(self.string(treasure["isCaseSensitive"]))
        let longitude = self.doubleString(self.string(treasure["longitude"]))
        let latitude = self.doubleString(self.string(treasure["latitude"]))
        let locationName = self.string(treasure["locationName"])
        let points = self.intString(self.string(treasure["points"]))
        let owner = self.intString(self.string(treasure["owner"]))
        let dateCreated = self.string(treasure["dateCreated"])
        let dateUpdated = self.string(treasure["dateUpdated"])
        
        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
        let gameTreasure = self.db.retrieveEntity(ARFConstants.entity.GAME_TREASURE, fromContext: ctx, filteredBy: predicate) as! GameTreasure
        
        gameTreasure.id = id
        gameTreasure.name = name
        gameTreasure.treasureDescription = treasureDescription
        gameTreasure.imageUrl = "\(self.serverUrl)/\(imageUrl)"
        gameTreasure.imageLocalName = imageLocalName
        gameTreasure.model3dUrl = "\(self.serverUrl)/\(model3dUrl)"
        gameTreasure.model3dLocalName = model3dLocalName
        gameTreasure.claimingQuestion = claimingQuestion
        gameTreasure.claimingAnswers = claimingAnswers
        gameTreasure.encryptedClaimingAnswers = encryptedClaimingAnswers
        gameTreasure.isCaseSensitive = isCaseSensitive
        gameTreasure.longitude = longitude
        gameTreasure.latitude = latitude
        gameTreasure.locationName = locationName
        gameTreasure.points = points
        gameTreasure.owner = owner
        gameTreasure.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
        gameTreasure.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
        gameTreasure.gameId = game.id
        gameTreasure.gpClassId = "\(self.loggedClassId)"
        gameTreasure.gpGameId = "\(game.id)"
        gameTreasure.gpIsDone = "0"
        gameTreasure.gpNumberOfAttempts = "0"
        gameTreasure.gpPlayerId = "\(self.loggedUserId)"
        gameTreasure.gpPlayerName = "\(self.loggedUserFullName)"
        gameTreasure.gpPoints = "0"
        gameTreasure.gpTreasureId = "\(id)"
        gameTreasure.gpTreasureName = name
        
        game.treasure = gameTreasure
        game.totalPoints = game.totalPoints + points
    }
    
    /// Attaches clues to a game.
    ///
    /// - parameters:
    ///     - clues : An array of clue details
    ///     - game  : A Game object
    fileprivate func relateClues(_ clues: [[String: Any]], toGame game: Game) {
        self.prettyFunction()
        
        guard let ctx = game.managedObjectContext else {
            print("ERROR: Can't retrieve game context!")
            return
        }
        
        var accumulatedPoints: Int64 = 0
        var order: Int64 = 1
        
        for c in clues {
            let id = self.intString(self.string(c["id"]))
            let type = self.intString(self.string(c["type"]))
            let riddle = self.string(c["riddle"])
            let longitude = self.doubleString(self.string(c["longitude"]))
            let latitude = self.doubleString(self.string(c["latitude"]))
            let locationName = self.string(c["locationName"])
            let points = self.intString(self.string(c["points"]))
            let pointsOnAttempts = self.string(c["pointsOnAttempts"])
            let clue = self.string(c["clue"])
            let owner = self.intString(self.string(c["owner"]))
            let dateCreated = self.string(c["dateCreated"])
            let dateUpdated = self.string(c["dateUpdated"])
            
            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
            let gameClue = self.db.retrieveEntity(ARFConstants.entity.GAME_CLUE, fromContext: ctx, filteredBy: predicate) as! GameClue
            
            gameClue.id = id
            gameClue.type = type
            gameClue.riddle = riddle
            gameClue.longitude = longitude
            gameClue.latitude = latitude
            gameClue.locationName = locationName
            gameClue.points = points
            gameClue.pointsOnAttempts = pointsOnAttempts
            gameClue.clue = clue
            gameClue.owner = owner
            gameClue.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
            gameClue.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
            gameClue.gameId = game.id
            gameClue.gpClassId = "\(self.loggedClassId)"
            gameClue.gpClueId = "\(id)"
            gameClue.gpClueName = "\(clue)"
            gameClue.gpGameId = "\(game.id)"
            gameClue.gpIsDone = "0"
            gameClue.gpNumberOfAttempts = "0"
            gameClue.gpPlayerId = "\(self.loggedUserId)"
            gameClue.gpPlayerName = "\(self.loggedUserFullName)"
            gameClue.gpPoints = "0"
            
            /// Set clue's order for the game play
            if game.startingClueId != id {
                gameClue.gpOrder = order
                order = order + 1
            }
            
            accumulatedPoints = accumulatedPoints + points
            
            // Choices
            if let choices = c["choices"] as? [[String: Any]] {
                self.relateChoices(choices, toGameClue: gameClue)
            }
            
            game.addToClues(gameClue)
        }
        
        game.totalPoints = game.totalPoints + accumulatedPoints
    }
    
    /// Attaches choices to a game clue.
    ///
    /// - parameters:
    ///     - choices   : A Dictionary identifying array of choices
    ///     - gameClue  : A GameClue object
    fileprivate func relateChoices(_ choices: [[String: Any]], toGameClue gameClue: GameClue) {
        self.prettyFunction()
        
        guard let ctx = gameClue.managedObjectContext else {
            print("ERROR: Can't retrieve game clue context!")
            return
        }
        
        for choice in choices {
            let id = self.intString(self.string(choice["id"]))
            let clueId = self.intString(self.string(choice["clueId"]))
            let choiceStatement = self.string(choice["choiceStatement"])
            let isCorrect = self.intString(self.string(choice["isCorrect"]))
            let answer = self.string(choice["answer"])
            let encryptedAnswer = self.string(choice["encryptedAnswer"])
            let isCaseSensitive = self.intString(self.string(choice["isCaseSensitive"]))
            let dateCreated = self.string(choice["dateCreated"])
            let dateUpdated = self.string(choice["dateUpdated"])
            
            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
            let gameClueChoice = self.db.retrieveEntity(ARFConstants.entity.GAME_CLUE_CHOICE, fromContext: ctx, filteredBy: predicate) as! GameClueChoice
            
            gameClueChoice.id = id
            gameClueChoice.clueId = clueId
            gameClueChoice.choiceStatement = choiceStatement
            gameClueChoice.isCorrect = isCorrect
            gameClueChoice.answer = answer
            gameClueChoice.encryptedAnswer = encryptedAnswer
            gameClueChoice.isCaseSensitive = isCaseSensitive
            gameClueChoice.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
            gameClueChoice.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
            gameClueChoice.gameId = gameClue.gameId
            
            gameClue.addToChoices(gameClueChoice)
        }
    }
    
    /// Retrieves class ids where game was deployed.
    ///
    /// - parameters:
    ///     - gameId    : A String identifying game's id
    ///     - completion: A completion handler
    func requestRetrieveClasses(forGameWithId gameId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_RETRIEVE_CLASSES_FOR_DEPLOYED_GAME)", gameId, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let classIds = rd["classIds"] as? [Int64] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let result: [String: Any] = ["status": 0, "message": message, "classIds": classIds]
                completion(result)
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Requests server to daploy game to classes.
    ///
    /// - parameters:
    ///     - id        : A String identifying game's id
    ///     - body      : A Dictionary identifying classes where to deploy
    ///     - completion: A completion handler
    func requestDeployGame(withId id: String, body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_DEPLOY_GAME)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Requests server to undaploy game from classes.
    ///
    /// - parameters:
    ///     - id        : A String identifying game's id
    ///     - body      : A Dictionary identifying classes where to undeploy
    ///     - completion: A completion handler
    func requestUndeployGame(withId id: String, body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_UNDEPLOY_GAME)", id, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Retrieves sidekick from the server.
    ///
    /// - parameters:
    ///     - playerId  : A String identifying player's id
    ///     - completion: A completion handler
    func requestRetrieveSidekick(forPlayerWithId playerId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.PLA_RETRIEVE_SIDEKICKS_FOR_PLAYER)", playerId, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
           
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let count = rd["count"] as? Int else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                if count > 0 {
                    guard let sidekick = rd["sidekick"] as? [String: Any] else {
                        print("ERROR: Request response data cannot be parsed!")
                        let result: [String: Any] = ["status": 1, "message": message]
                        completion(result)
                        return
                    }
                    
                    guard let ctx = self.db.retrieveObjectWorkerContext() else {
                        print("ERROR: Can't retrieve worker context!")
                        let result: [String: Any] = ["status": 1, "message": message]
                        completion(result)
                        return
                    }
                    
                    let cleared = self.db.clearEntities([ARFConstants.entity.SIDEKICK])
                    
                    if cleared {
                        ctx.performAndWait {
                            let id = self.intString(self.string(sidekick["id"]))
                            let type = self.intString(self.string(sidekick["type"]))
                            let name = self.string(sidekick["name"])
                            let level = self.intString(self.string(sidekick["level"]))
                            let points = self.intString(self.string(sidekick["points"]))
                            let ownedBy = self.intString(self.string(sidekick["ownedBy"]))
                            let dateCreated = self.string(sidekick["dateCreated"])
                            let dateUpdated = self.string(sidekick["dateUpdated"])
                            
                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let aSidekick = self.db.retrieveEntity(ARFConstants.entity.SIDEKICK, fromContext: ctx, filteredBy: predicate) as! Sidekick
                            
                            aSidekick.id = id
                            aSidekick.type = type
                            aSidekick.name = name
                            aSidekick.level = level
                            aSidekick.points = points
                            aSidekick.ownedBy = ownedBy
                            aSidekick.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                            aSidekick.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                            
                            let saved = self.db.saveObjectContext(ctx)

                            if saved {
                                let result: [String: Any] = ["status": 0, "message": rMessage, "count": count]
                                completion(result)
                                return
                            }
                            else {
                                print("ERROR: Can't save sidekick's details in core data!")
                                let result: [String: Any] = ["status": 1, "message": message]
                                completion(result)
                                return
                            }
                        }
                    }
                    else {
                        print("ERROR: Can't clear sidekick entity!")
                        let result: [String: Any] = ["status": 1, "message": message]
                        completion(result)
                        return
                    }
                }
                else {
                    print("ERROR: Empty sidekick!")
                    let result: [String: Any] = ["status": 0, "message": message, "count": count]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Requests server to create a new sidekick.
    ///
    /// - parameters:
    ///     - body      : A Dictionary identifying data to be created
    ///     - completion: A completion handler
    func requestCreateSidekick(withBody body: [String: Any], completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.PLA_CREATE_SIDEKICK)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Retrieves activities from the server.
    ///
    /// - parameter completion: A completion handler
    func requestRetrieveActivities(_ completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.STA_RETRIEVE_ACTIVITIES)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let activities = rd["activities"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.ACTIVITY])
                
                if cleared {
                    ctx.performAndWait {
                        for a in activities {
                            let id = self.intString(self.string(a["id"]))
                            let activity = self.string(a["activity"])
                            let module = self.string(a["module"])
                            let userId = self.intString(self.string(a["userId"]))
                            let date = self.string(a["date"])

                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let aActivity = self.db.retrieveEntity(ARFConstants.entity.ACTIVITY, fromContext: ctx, filteredBy: predicate) as! Activity
                            
                            aActivity.id = id
                            aActivity.activity = activity
                            aActivity.module = module
                            aActivity.userId = userId
                            aActivity.date = self.date(fromString: date, format: ARFConstants.timeFormat.SERVER)
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": activities.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save activity's details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear activity entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Retrieves number of users, courses and classes stored
    /// in the database
    ///
    /// - parameters:
    ///     - userId    : A String identifying user id
    ///     - completion: A completion handler
    func requestRetrieveStatisticsAdministratorDashboardPrimary(forUserWithId userId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.STA_RETRIEVE_ADMIN_DASHBOARD_PRI)", userId)
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let users = rd["users"] as? Int64, let courses = rd["courses"] as? Int64, let classes = rd["classes"] as? Int64 else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let statistics: [String: Int64] = ["users": users, "courses": courses, "classes": classes]
                let result: [String: Any] = ["status": 0, "message": rMessage, "statistics": statistics]
                completion(result)
                return
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Retrieves number of clues, treasures and games stored
    /// in the database.
    ///
    /// - parameters:
    ///     - userId    : A String identifying user id
    ///     - completion: A completion handler
    func requestRetrieveStatisticsCreatorDashboardPrimary(forUserWithId userId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.STA_RETRIEVE_CREATOR_DASHBOARD_PRI)", userId)
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let clues = rd["clues"] as? Int64, let treasures = rd["treasures"] as? Int64, let games = rd["games"] as? Int64 else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let statistics: [String: Int64] = ["clues": clues, "treasures": treasures, "games": games]
                let result: [String: Any] = ["status": 0, "message": rMessage, "statistics": statistics]
                completion(result)
                return
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Retrives game result for deplyed in a class.
    ///
    /// - parameters:
    ///     - classId   : A String identifying class id
    ///     - gameId    : A String identifying game id
    ///     - completion: A completion handler
    func requestRetrieveGameResult(forClassWithId classId: String, andGameId gameId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_RETRIEVE_GAME_RESULT)", classId, gameId, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let gameResult = rd["gameResult"] as? String else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let result: [String: Any] = ["status": 0, "message": rMessage, "gameResult": gameResult]
                completion(result)
                return
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Retrieves details of each game that has been played by
    /// a player
    ///
    /// - parameters:
    ///     - classId   : A String identifying class id
    ///     - playerId  : A String identifying player id
    ///     - completion: A completion handler
    func requestRetrieveFinishedGames(forClassWithId classId: String, playerId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_RETRIEVE_FINISHED_GAMES)", classId, playerId, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let games = rd["games"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.FINISHED_GAME])
                
                if cleared {
                    ctx.performAndWait {
                        for game in games {
                            let gameId = self.intString(self.string(game["gameId"]))
                            let imageUrl = self.string(game["imageUrl"])
                            
                            let predicate = self.predicate(forKeyPath: "gameId", exactValue: "\(gameId)")
                            let aGame = self.db.retrieveEntity(ARFConstants.entity.FINISHED_GAME, fromContext: ctx, filteredBy: predicate) as! FinishedGame

                            aGame.gameId = gameId
                            aGame.imageUrl = "\(self.serverUrl)/\(imageUrl)"
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": games.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save finished game details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear finished game entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Retrieves unlocked treasures for player with id.
    ///
    /// - parameters:
    ///     - playerId  : A String identifying player id
    ///     - completion: A completion handler
    func requestRetrieveUnlockedTreasures(forPlayerWithId playerId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_RETRIEVE_UNLOCKED_TREASURES)", playerId, "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let treasures = rd["treasures"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.TREASURE])
                
                if cleared {
                    ctx.performAndWait {
                        for treasure in treasures {
                            let id = self.intString(self.string(treasure["id"]))
                            let name = self.string(treasure["name"])
                            let treasureDescription = self.string(treasure["treasureDescription"])
                            let imageUrl = self.string(treasure["imageUrl"])
                            let imageLocalName = self.string(treasure["imageLocalName"])
                            let model3dUrl = self.string(treasure["model3dUrl"])
                            let model3dLocalName = self.string(treasure["model3dLocalName"])
                            let claimingQuestion = self.string(treasure["claimingQuestion"])
                            let claimingAnswers = self.string(treasure["claimingAnswers"])
                            let encryptedClaimingAnswers = self.string(treasure["encryptedClaimingAnswers"])
                            let isCaseSensitive = self.intString(self.string(treasure["isCaseSensitive"]))
                            let longitude = self.doubleString(self.string(treasure["longitude"]))
                            let latitude = self.doubleString(self.string(treasure["latitude"]))
                            let locationName = self.string(treasure["locationName"])
                            let points = self.intString(self.string(treasure["points"]))
                            let owner = self.intString(self.string(treasure["owner"]))
                            let dateCreated = self.string(treasure["dateCreated"])
                            let dateUpdated = self.string(treasure["dateUpdated"])
                            let searchString = "\(id)\(name)\(treasureDescription)"
                            
                            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                            let aTreasure = self.db.retrieveEntity(ARFConstants.entity.TREASURE, fromContext: ctx, filteredBy: predicate) as! Treasure
                            
                            aTreasure.id = id
                            aTreasure.name = name
                            aTreasure.treasureDescription = treasureDescription
                            aTreasure.imageUrl = "\(self.serverUrl)/\(imageUrl)"
                            aTreasure.imageLocalName = imageLocalName
                            aTreasure.model3dUrl = "\(self.serverUrl)/\(model3dUrl)"
                            aTreasure.model3dLocalName = model3dLocalName
                            aTreasure.claimingQuestion = claimingQuestion
                            aTreasure.claimingAnswers = claimingAnswers
                            aTreasure.encryptedClaimingAnswers = encryptedClaimingAnswers
                            aTreasure.isCaseSensitive = isCaseSensitive
                            aTreasure.longitude = longitude
                            aTreasure.latitude = latitude
                            aTreasure.locationName = locationName
                            aTreasure.points = points
                            aTreasure.owner = owner
                            aTreasure.dateCreated = self.date(fromString: dateCreated, format: ARFConstants.timeFormat.SERVER)
                            aTreasure.dateUpdated = self.date(fromString: dateUpdated, format: ARFConstants.timeFormat.SERVER)
                            aTreasure.searchString = searchString
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": treasures.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save treasure's details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear treasure entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Retrieves players for ranking from the server.
    ///
    /// - parameter completion: A completion handler
    func requestRetrievePlayers(_ completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.PLA_RETRIEVE_PLAYERS_FOR_RANKING)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let players = rd["players"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                guard let ctx = self.db.retrieveObjectWorkerContext() else {
                    print("ERROR: Can't retrieve worker context!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let cleared = self.db.clearEntities([ARFConstants.entity.PLAYER_RANKING])
                
                if cleared {
                    ctx.performAndWait {
                        for player in players {
                            let playerId = self.intString(self.string(player["playerId"]))
                            let playerName = self.string(player["playerName"])
                            let playerImageUrl = self.string(player["playerImageUrl"])
                            let level = self.intString(self.string(player["level"]))
                            let points = self.intString(self.string(player["points"]))
                            
                            let predicate = self.predicate(forKeyPath: "playerId", exactValue: "\(playerId)")
                            let aPlayer = self.db.retrieveEntity(ARFConstants.entity.PLAYER_RANKING, fromContext: ctx, filteredBy: predicate) as! PlayerRanking
                            
                            aPlayer.playerId = playerId
                            aPlayer.playerName = playerName
                            aPlayer.playerImageUrl = "\(self.serverUrl)/\(playerImageUrl)"
                            aPlayer.level = level
                            aPlayer.points = points
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        
                        if saved {
                            let result: [String: Any] = ["status": 0, "message": rMessage, "count": players.count]
                            completion(result)
                            return
                        }
                        else {
                            print("ERROR: Can't save player's details in core data!")
                            let result: [String: Any] = ["status": 1, "message": message]
                            completion(result)
                            return
                        }
                    }
                }
                else {
                    print("ERROR: Can't clear player for ranking entity!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }
    
    /// Requests server to create a new sidekick.
    ///
    /// - parameters:
    ///     - body      : A Dictionary identifying data to be created
    ///     - completion: A completion handler
    func requestSubmitGameResult(forGameWithId gameId: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let body = self.assembleGameResultPostData(forGameWithId: gameId)
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.GAM_SUBMIT_GAME_RESULT)", "\(self.loggedUserId)")
        let message = ARFConstants.message.DEFAULT_ERROR
        
        if body == nil {
            print("ERROR: Post body is nil!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        guard let request = self.route(uri, withBody: body as AnyObject) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            let result: [String: Any] = ["status": status, "message": rMessage]
            completion(result)
            return
        }
        
        task.resume()
    }
    
    /// Retrieves class ids where game was deployed.
    ///
    /// - parameters:
    ///     - gameId    : A String identifying game's id
    ///     - completion: A completion handler
    func requestRetrieveGameSuccessRate(forUserWithId id: String, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        let uri = String(format: "\(serverUrl)/\(ARFConstants.endPoint.STA_RETRIEVE_GAME_PERCENTAGE_SUCCESS)", id)
        let message = ARFConstants.message.DEFAULT_ERROR
        
        guard let request = self.route(uri, forMethod: "GET", andBody: nil) else {
            print("ERROR: Can't create request from the given uri!")
            let result: [String: Any] = ["status": 1, "message": message]
            completion(result)
            return
        }
        
        let task = self.session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                let result: [String: Any] = ["status": 1, "message": error!.localizedDescription]
                completion(result)
                return
            }
            
            if data == nil {
                print("ERROR: Received data from server is nil!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            guard let json = self.json(fromData: data!) as? [String: Any] else {
                print("ERROR: Can't parse JSON data!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            print("REQUEST RESULT: \(json)")
            
            guard let status = json["status"] as? Int, let rMessage = json["message"] as? String else {
                print("ERROR: Request response status or message cannot be parsed!")
                let result: [String: Any] = ["status": 1, "message": message]
                completion(result)
                return
            }
            
            if status == 0 {
                guard let rd = json["data"] as? [String: Any], let gpos = rd["gpos"] as? [[String: Any]] else {
                    print("ERROR: Request response data cannot be parsed!")
                    let result: [String: Any] = ["status": 1, "message": message]
                    completion(result)
                    return
                }
                
                let result: [String: Any] = ["status": 0, "message": message, "gpos": gpos]
                completion(result)
            }
            else {
                let result: [String: Any] = ["status": 1, "message": rMessage]
                completion(result)
                return
            }
        }
        
        task.resume()
    }

    
    // MARK: - Data Filters

    func predicate(forKeyPath keyPath: String, exactValue: String) -> NSPredicate {
        let leftExpression = NSExpression(forKeyPath: keyPath)
        let rightExpression = NSExpression(forConstantValue: exactValue)
        let options: NSComparisonPredicate.Options = [.diacriticInsensitive, .caseInsensitive]
        let predicate = NSComparisonPredicate(leftExpression: leftExpression, rightExpression: rightExpression, modifier: .direct, type: .equalTo, options: options)

        return predicate
    }

    func predicate(forKeyPath keyPath: String, containsValue: String) -> NSPredicate {
        let leftExpression = NSExpression(forKeyPath: keyPath)
        let rightExpression = NSExpression(forConstantValue: containsValue)
        let options: NSComparisonPredicate.Options = [.diacriticInsensitive, .caseInsensitive]
        let predicate = NSComparisonPredicate(leftExpression: leftExpression, rightExpression: rightExpression, modifier: .direct, type: .contains, options: options)

        return predicate
    }
    
    func predicate(forKeyPath keyPath: String, notValue: String) -> NSPredicate {
        let leftExpression = NSExpression(forKeyPath: keyPath)
        let rightExpression = NSExpression(forConstantValue: notValue)
        let options: NSComparisonPredicate.Options = [.diacriticInsensitive, .caseInsensitive]
        let predicate = NSComparisonPredicate(leftExpression: leftExpression, rightExpression: rightExpression, modifier: .direct, type: .notEqualTo, options: options)
        
        return predicate
    }
    
    // MARK: - Other Core Data Related Methods
    
    /// Creates a copy of user object in preparation for
    /// creating or updating a user.
    ///
    /// - parameters:
    ///     - object    : A User object
    ///     - owner     : An Int64 identifying user creator's id
    ///     - isCreation: A Bool identifying selection action (create or update)
    ///     - completion: A completion handler
    func deepCopyUserObject(_ object: User?, owner: Int64, isCreation: Bool, isRegistration: Bool = false, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(nil)
            return
        }
        
        let cleared = self.db.clearEntities([ARFConstants.entity.DEEP_COPY_USER])
        
        if cleared {
            ctx.performAndWait {
                if isCreation {
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "")
                    let deepCopyUser = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_USER, fromContext: ctx, filteredBy: predicate) as! DeepCopyUser
                    
                    deepCopyUser.id = 0
                    deepCopyUser.lastName = ""
                    deepCopyUser.firstName = ""
                    deepCopyUser.middleName = ""
                    deepCopyUser.gender = 0
                    deepCopyUser.birthdate = ""
                    deepCopyUser.address = ""
                    deepCopyUser.mobile = ""
                    deepCopyUser.email = ""
                    deepCopyUser.type = 2
                    deepCopyUser.username = ""
                    deepCopyUser.encryptedUsername = ""
                    deepCopyUser.password = ""
                    deepCopyUser.encryptedPassword = ""
                    deepCopyUser.imageUrl = ""
                    deepCopyUser.isForApproval = isRegistration ? "1" : "0"
                    deepCopyUser.owner = owner
                    deepCopyUser.confirmPassword = ""
                    deepCopyUser.imageData = nil
                    
                    let saved = self.db.saveObjectContext(ctx)
                    completion(saved ? ["user": deepCopyUser] : nil)
                }
                else {
                    if let o = object {
                        let id = self.intString("\(o.id)")
                        let lastName = self.string(o.lastName)
                        let firstName = self.string(o.firstName)
                        let middleName = self.string(o.middleName)
                        let gender = self.intString("\(o.gender)")
                        let birthdate = self.string(o.birthdate)
                        let address = self.string(o.address)
                        let mobile = self.string(o.mobile)
                        let email = self.string(o.email)
                        let type = self.intString("\(o.type)")
                        let username = self.string(o.username)
                        let encryptedUsername = self.string(o.encryptedUsername)
                        let password = self.string(o.password)
                        let encryptedPassword = self.string(o.encryptedPassword)
                        let imageUrl = self.string(o.imageUrl)
                        let isForApproval = self.string(o.isForApproval)
                        let aOwner = self.intString("\(o.owner)")
                        
                        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                        let deepCopyUser = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_USER, fromContext: ctx, filteredBy: predicate) as! DeepCopyUser
                        
                        deepCopyUser.id = id
                        deepCopyUser.lastName = lastName
                        deepCopyUser.firstName = firstName
                        deepCopyUser.middleName = middleName
                        deepCopyUser.gender = gender
                        deepCopyUser.birthdate = birthdate
                        deepCopyUser.address = address
                        deepCopyUser.mobile = mobile
                        deepCopyUser.email = email
                        deepCopyUser.type = type
                        deepCopyUser.username = username
                        deepCopyUser.encryptedUsername = encryptedUsername
                        deepCopyUser.password = password
                        deepCopyUser.encryptedPassword = encryptedPassword
                        deepCopyUser.imageUrl = imageUrl
                        deepCopyUser.isForApproval = isForApproval
                        deepCopyUser.owner = aOwner
                        deepCopyUser.confirmPassword = password
                        deepCopyUser.encryptedConfirmPassword = encryptedPassword
                        deepCopyUser.imageData = nil
                        
                        let saved = self.db.saveObjectContext(ctx)
                        completion(saved ? ["user": deepCopyUser] : nil)
                    }
                    else {
                        print("ERROR: Passed user object is nil!")
                        completion(nil)
                    }
                }
            }
        }
        else {
            print("ERROR: Can't clear deep copy user entity!")
            completion(nil)
        }
    }
    
    /// Creates a copy of course object in preparation for
    /// creating or updating a course.
    ///
    /// - parameters:
    ///     - object    : A Course object
    ///     - owner     : An Int64 identifying course creator's id
    ///     - isCreation: A Bool identifying selection action (create or update)
    ///     - completion: A completion handler
    func deepCopyCourseObject(_ object: Course?, owner: Int64, isCreation: Bool, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(nil)
            return
        }
        
        let cleared = self.db.clearEntities([ARFConstants.entity.DEEP_COPY_COURSE])
        
        if cleared {
            ctx.performAndWait {
                if isCreation {
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "")
                    let deepCopyCourse = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_COURSE, fromContext: ctx, filteredBy: predicate) as! DeepCopyCourse
                    
                    deepCopyCourse.id = 0
                    deepCopyCourse.code = ""
                    deepCopyCourse.title = ""
                    deepCopyCourse.courseDescription = ""
                    deepCopyCourse.unit = 0
                    deepCopyCourse.owner = owner
                    
                    let saved = self.db.saveObjectContext(ctx)
                    completion(saved ? ["course": deepCopyCourse] : nil)
                }
                else {
                    if let o = object {
                        let id = self.intString("\(o.id)")
                        let code = self.string(o.code)
                        let title = self.string(o.title)
                        let courseDescription = self.string(o.courseDescription)
                        let unit = self.intString("\(o.unit)")
                        let aOwner = self.intString("\(o.owner)")
                        
                        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                        let deepCopyCourse = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_COURSE, fromContext: ctx, filteredBy: predicate) as! DeepCopyCourse
                        
                        deepCopyCourse.id = id
                        deepCopyCourse.code = code
                        deepCopyCourse.title = title
                        deepCopyCourse.courseDescription = courseDescription
                        deepCopyCourse.unit = unit
                        deepCopyCourse.owner = aOwner
                        
                        let saved = self.db.saveObjectContext(ctx)
                        completion(saved ? ["course": deepCopyCourse] : nil)
                    }
                    else {
                        print("ERROR: Passed course object is nil!")
                        completion(nil)
                    }
                }
            }
        }
        else {
            print("ERROR: Can't clear deep copy course entity!")
            completion(nil)
        }
    }
    
    /// Creates a copy of class object in preparation for
    /// creating or updating a class.
    ///
    /// - parameters:
    ///     - object    : A Class object
    ///     - owner     : An Int64 identifying class creator's id
    ///     - isCreation: A Bool identifying selection action (create or update)
    ///     - completion: A completion handler
    func deepCopyClassObject(_ object: Class?, owner: Int64, isCreation: Bool, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(nil)
            return
        }
        
        let cleared = self.db.clearEntities([ARFConstants.entity.DEEP_COPY_CLASS,
                                             ARFConstants.entity.DEEP_COPY_CLASS_COURSE,
                                             ARFConstants.entity.DEEP_COPY_CLASS_CREATOR,
                                             ARFConstants.entity.DEEP_COPY_CLASS_PLAYER])
        
        if cleared {
            ctx.performAndWait {
                if isCreation {
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "")
                    let deepCopyClass = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLASS, fromContext: ctx, filteredBy: predicate) as! DeepCopyClass
                    
                    deepCopyClass.id = 0
                    deepCopyClass.code = ""
                    deepCopyClass.aClassDescription = ""
                    deepCopyClass.schedule = ""
                    deepCopyClass.venue = ""
                    deepCopyClass.courseId = 0
                    deepCopyClass.creatorId = 0
                    deepCopyClass.playerIds = ""
                    deepCopyClass.courseCode = ""
                    deepCopyClass.creatorName = ""
                    deepCopyClass.owner = owner
                    
                    let saved = self.db.saveObjectContext(ctx)
                    completion(saved ? ["class": deepCopyClass] : nil)
                }
                else {
                    if let o = object {
                        let id = self.intString("\(o.id)")
                        let code = self.string(o.code)
                        let aClassDescription = self.string(o.aClassDescription)
                        let schedule = self.string(o.schedule)
                        let venue = self.string(o.venue)
                        let aOwner = self.intString("\(o.owner)")
                        
                        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                        let deepCopyClass = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLASS, fromContext: ctx, filteredBy: predicate) as! DeepCopyClass
                        
                        deepCopyClass.id = id
                        deepCopyClass.code = code
                        deepCopyClass.aClassDescription = aClassDescription
                        deepCopyClass.schedule = schedule
                        deepCopyClass.venue = venue
                        deepCopyClass.courseId = 0
                        deepCopyClass.creatorId = 0
                        deepCopyClass.playerIds = ""
                        deepCopyClass.courseCode = ""
                        deepCopyClass.creatorName = ""
                        deepCopyClass.owner = aOwner
                        
                        // Relate class course to deep copy class
                        if let classCourse = o.course { self.relateClassCourse(classCourse, toDeepCopyClass: deepCopyClass) }
                        
                        // Relate class creator to deep copy class
                        if let classCreator = o.creator { self.relateClassCreator(classCreator, toDeepCopyClass: deepCopyClass) }
                        
                        // Relate class players to deep copy class
                        if let classPlayers = o.players?.allObjects as? [ClassPlayer] { self.relateClassPlayers(classPlayers, toDeepCopyClass: deepCopyClass) }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        completion(saved ? ["class": deepCopyClass] : nil)
                    }
                    else {
                        print("ERROR: Passed class object is nil!")
                        completion(nil)
                    }
                }
            }
        }
        else {
            print("ERROR: Can't clear deep copy class entity!")
            completion(nil)
        }
    }
    
    /// Attaches class course to deep copy class.
    ///
    /// - parameters:
    ///     - classCourse   : A ClassCourse object
    ///     - deepCopyClass : A DeepCopyClass object
    fileprivate func relateClassCourse(_ classCourse: ClassCourse, toDeepCopyClass deepCopyClass: DeepCopyClass) {
        self.prettyFunction()
        
        guard let ctx = deepCopyClass.managedObjectContext else {
            print("ERROR: Can't retrieve deep copy class context!")
            return
        }
        
        let id = self.intString("\(classCourse.id)")
        let code = self.string(classCourse.code)
        let title = self.string(classCourse.title)
        let courseDescription = self.string(classCourse.courseDescription)
        let unit = self.intString("\(classCourse.unit)")
        let owner = self.intString("\(classCourse.owner)")

        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
        let deepCopyClassCourse = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLASS_COURSE, fromContext: ctx, filteredBy: predicate) as! DeepCopyClassCourse
        
        deepCopyClassCourse.id = id
        deepCopyClassCourse.code = code
        deepCopyClassCourse.title = title
        deepCopyClassCourse.courseDescription = courseDescription
        deepCopyClassCourse.unit = unit
        deepCopyClassCourse.owner = owner
        deepCopyClassCourse.classId = deepCopyClass.id
        
        deepCopyClass.courseId = id
        deepCopyClass.courseCode = code
        deepCopyClass.deepCopyCourse = deepCopyClassCourse
    }
    
    /// Attaches class creator to deep copy class.
    ///
    /// - parameters:
    ///     - classCreator  : A ClassCreator object
    ///     - deepCopyClass : A DeepCopyClass object
    fileprivate func relateClassCreator(_ classCreator: ClassCreator, toDeepCopyClass deepCopyClass: DeepCopyClass) {
        self.prettyFunction()
        
        guard let ctx = deepCopyClass.managedObjectContext else {
            print("ERROR: Can't retrieve deep copy class context!")
            return
        }
        
        let id = self.intString("\(classCreator.id)")
        let lastName = self.string(classCreator.lastName)
        let firstName = self.string(classCreator.firstName)
        let middleName = self.string(classCreator.middleName)
        let gender = self.intString("\(classCreator.gender)")
        let birthdate = self.string(classCreator.birthdate)
        let address = self.string(classCreator.address)
        let mobile = self.string(classCreator.mobile)
        let email = self.string(classCreator.email)
        let type = self.intString("\(classCreator.type)")
        let username = self.string(classCreator.username)
        let encryptedUsername = self.string(classCreator.encryptedUsername)
        let password = self.string(classCreator.password)
        let encryptedPassword = self.string(classCreator.encryptedPassword)
        let imageUrl = self.string(classCreator.imageUrl)
        let owner = self.intString("\(classCreator.owner)")
        
        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
        let deepCopyClassCreator = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLASS_CREATOR, fromContext: ctx, filteredBy: predicate) as! DeepCopyClassCreator
        
        deepCopyClassCreator.id = id
        deepCopyClassCreator.lastName = lastName
        deepCopyClassCreator.firstName = firstName
        deepCopyClassCreator.middleName = middleName
        deepCopyClassCreator.gender = gender
        deepCopyClassCreator.birthdate = birthdate
        deepCopyClassCreator.address = address
        deepCopyClassCreator.mobile = mobile
        deepCopyClassCreator.email = email
        deepCopyClassCreator.type = type
        deepCopyClassCreator.username = username
        deepCopyClassCreator.encryptedUsername = encryptedUsername
        deepCopyClassCreator.password = password
        deepCopyClassCreator.encryptedPassword = encryptedPassword
        deepCopyClassCreator.imageUrl = imageUrl
        deepCopyClassCreator.owner = owner
        deepCopyClassCreator.classId = deepCopyClass.id
        
        deepCopyClass.creatorId = id
        deepCopyClass.creatorName = middleName == "" ? "\(firstName) \(lastName)" : "\(firstName) \(middleName) \(lastName)"
        deepCopyClass.deepCopyCreator = deepCopyClassCreator
    }
    
    /// Attaches class players to deep copy class.
    ///
    /// - parameters:
    ///     - players       : An Array identifying list of class player objects
    ///     - deepCopyClass : A DeepCopyClass object
    fileprivate func relateClassPlayers (_ players: [ClassPlayer], toDeepCopyClass deepCopyClass: DeepCopyClass) {
        self.prettyFunction()
        
        guard let ctx = deepCopyClass.managedObjectContext else {
            print("ERROR: Can't retrieve deep copy class context!")
            return
        }
        
        var concatPlayers = ""
        
        for p in players {
            let id = self.intString("\(p.id)")
            let lastName = self.string(p.lastName)
            let firstName = self.string(p.firstName)
            let middleName = self.string(p.middleName)
            let gender = self.intString("\(p.gender)")
            let birthdate = self.string(p.birthdate)
            let address = self.string(p.address)
            let mobile = self.string(p.mobile)
            let email = self.string(p.email)
            let type = self.intString("\(p.type)")
            let username = self.string(p.username)
            let encryptedUsername = self.string(p.encryptedUsername)
            let password = self.string(p.password)
            let encryptedPassword = self.string(p.encryptedPassword)
            let imageUrl = self.string(p.imageUrl)
            let owner = self.intString("\(p.owner)")
            
            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
            let deepCopyClassPlayer = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLASS_PLAYER, fromContext: ctx, filteredBy: predicate) as! DeepCopyClassPlayer
            
            deepCopyClassPlayer.id = id
            deepCopyClassPlayer.lastName = lastName
            deepCopyClassPlayer.firstName = firstName
            deepCopyClassPlayer.middleName = middleName
            deepCopyClassPlayer.gender = gender
            deepCopyClassPlayer.birthdate = birthdate
            deepCopyClassPlayer.address = address
            deepCopyClassPlayer.mobile = mobile
            deepCopyClassPlayer.email = email
            deepCopyClassPlayer.type = type
            deepCopyClassPlayer.username = username
            deepCopyClassPlayer.encryptedUsername = encryptedUsername
            deepCopyClassPlayer.password = password
            deepCopyClassPlayer.encryptedPassword = encryptedPassword
            deepCopyClassPlayer.imageUrl = imageUrl
            deepCopyClassPlayer.owner = owner
            deepCopyClassPlayer.classId = deepCopyClass.id
            
            concatPlayers = "\(concatPlayers == "" ? "" : "\(concatPlayers),")\(id)"
            deepCopyClass.addToDeepCopyPlayers(deepCopyClassPlayer)
        }
        
        deepCopyClass.playerIds = concatPlayers
    }
    
    /// Attaches course to deep copy class.
    ///
    /// - parameters:
    ///     - id        : An Int64 identifying course id
    ///     - classId   : An Int64 identifying class id
    ///     - completion: A completion handler
    func relateCourse(withId courseId: Int64, toDeepCopyClassWithId classId: Int64, completion: @escaping ARFDMDoneBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(false)
            return
        }
        
        ctx.performAndWait {
            let predicateA = self.predicate(forKeyPath: "id", exactValue: "\(classId)")
            
            guard let deepCopyClass = self.db.retrieveObject(forEntity: ARFConstants.entity.DEEP_COPY_CLASS, filteredBy: predicateA) as? DeepCopyClass else {
                print("ERROR: Can't retrieve deep copy class!")
                completion(false)
                return
            }
            
            let cleared = self.db.clearEntities([ARFConstants.entity.DEEP_COPY_CLASS_COURSE])
            
            if cleared {
                let predicateB = self.predicate(forKeyPath: "id", exactValue: "\(courseId)")
                
                if let course = self.db.retrieveObject(forEntity: ARFConstants.entity.COURSE, filteredBy: predicateB) as? Course {
                    let id = self.intString("\(course.id)")
                    let code = self.string(course.code)
                    let title = self.string(course.title)
                    let courseDescription = self.string(course.courseDescription)
                    let unit = self.intString("\(course.unit)")
                    let owner = self.intString("\(course.owner)")
                
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                    let deepCopyClassCourse = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLASS_COURSE, fromContext: ctx, filteredBy: predicate) as! DeepCopyClassCourse
                    
                    deepCopyClassCourse.id = id
                    deepCopyClassCourse.code = code
                    deepCopyClassCourse.title = title
                    deepCopyClassCourse.courseDescription = courseDescription
                    deepCopyClassCourse.unit = unit
                    deepCopyClassCourse.owner = owner
                    deepCopyClassCourse.classId = deepCopyClass.id
                    
                    deepCopyClass.courseId = id
                    deepCopyClass.courseCode = code
                    deepCopyClass.deepCopyCourse = deepCopyClassCourse
                }
                
                let saved = self.db.saveObjectContext(ctx)
                completion(saved)
            }
            else {
                completion(false)
            }
        }
    }
    
    /// Attaches users as creators or players to deep copy
    /// class.
    ///
    /// - parameters:
    ///     - ids       : Array of Int64 identifying user ids
    ///     - classId   : An Int64 identifying class id
    ///     - isCreator : A Boolean identifying user's type
    ///     - completion: A completion handler
    func relateUsers(withIds ids: [Int64], toDeepCopyClassWithId classId: Int64, isCreator: Bool, completion: @escaping ARFDMDoneBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(false)
            return
        }

        ctx.performAndWait {
            let predicateA = self.predicate(forKeyPath: "id", exactValue: "\(classId)")
            
            guard let deepCopyClass = self.db.retrieveObject(forEntity: ARFConstants.entity.DEEP_COPY_CLASS, filteredBy: predicateA) as? DeepCopyClass else {
                print("ERROR: Can't retrieve deep copy class!")
                completion(false)
                return
            }
            
            let entity = isCreator ? ARFConstants.entity.DEEP_COPY_CLASS_CREATOR : ARFConstants.entity.DEEP_COPY_CLASS_PLAYER
            let cleared = self.db.clearEntities([entity])
            if !isCreator { deepCopyClass.playerIds = "" }
            
            if cleared {
                for id in ids {
                    let predicateB = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                    if let user = self.db.retrieveObject(forEntity: ARFConstants.entity.USER, filteredBy: predicateB) as? User {
                        isCreator ? self.relateUserAsCreator(user, toDeepCopyClass: deepCopyClass) : self.relateUserAsPlayer(user, toDeepCopyClass: deepCopyClass)
                    }
                }
                
                let saved = self.db.saveObjectContext(ctx)
                completion(saved)
            }
            else {
                completion(false)
            }
        }
    }
    
    /// Attaches class creator to deep copy class.
    ///
    /// - parameters:
    ///     - user          : A User object
    ///     - deepCopyClass : A DeepCopyClass object
    fileprivate func relateUserAsCreator(_ user: User, toDeepCopyClass deepCopyClass: DeepCopyClass) {
        self.prettyFunction()
        
        guard let ctx = deepCopyClass.managedObjectContext else {
            print("ERROR: Can't retrieve deep copy class context!")
            return
        }
        
        let id = self.intString("\(user.id)")
        let lastName = self.string(user.lastName)
        let firstName = self.string(user.firstName)
        let middleName = self.string(user.middleName)
        let gender = self.intString("\(user.gender)")
        let birthdate = self.string(user.birthdate)
        let address = self.string(user.address)
        let mobile = self.string(user.mobile)
        let email = self.string(user.email)
        let type = self.intString("\(user.type)")
        let username = self.string(user.username)
        let encryptedUsername = self.string(user.encryptedUsername)
        let password = self.string(user.password)
        let encryptedPassword = self.string(user.encryptedPassword)
        let imageUrl = self.string(user.imageUrl)
        let owner = self.intString("\(user.owner)")
        
        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
        let deepCopyClassCreator = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLASS_CREATOR, fromContext: ctx, filteredBy: predicate) as! DeepCopyClassCreator
        
        deepCopyClassCreator.id = id
        deepCopyClassCreator.lastName = lastName
        deepCopyClassCreator.firstName = firstName
        deepCopyClassCreator.middleName = middleName
        deepCopyClassCreator.gender = gender
        deepCopyClassCreator.birthdate = birthdate
        deepCopyClassCreator.address = address
        deepCopyClassCreator.mobile = mobile
        deepCopyClassCreator.email = email
        deepCopyClassCreator.type = type
        deepCopyClassCreator.username = username
        deepCopyClassCreator.encryptedUsername = encryptedUsername
        deepCopyClassCreator.password = password
        deepCopyClassCreator.encryptedPassword = encryptedPassword
        deepCopyClassCreator.imageUrl = imageUrl
        deepCopyClassCreator.owner = owner
        deepCopyClassCreator.classId = deepCopyClass.id
        
        deepCopyClass.creatorId = id
        deepCopyClass.creatorName = middleName == "" ? "\(firstName) \(lastName)" : "\(firstName) \(middleName) \(lastName)"
        deepCopyClass.deepCopyCreator = deepCopyClassCreator
    }
    
    /// Attaches class player to deep copy class.
    ///
    /// - parameters:
    ///     - user          : A User object
    ///     - deepCopyClass : A DeepCopyClass object
    fileprivate func relateUserAsPlayer(_ user: User, toDeepCopyClass deepCopyClass: DeepCopyClass) {
        self.prettyFunction()
        
        guard let ctx = deepCopyClass.managedObjectContext else {
            print("ERROR: Can't retrieve deep copy class context!")
            return
        }
        
        let id = self.intString("\(user.id)")
        let lastName = self.string(user.lastName)
        let firstName = self.string(user.firstName)
        let middleName = self.string(user.middleName)
        let gender = self.intString("\(user.gender)")
        let birthdate = self.string(user.birthdate)
        let address = self.string(user.address)
        let mobile = self.string(user.mobile)
        let email = self.string(user.email)
        let type = self.intString("\(user.type)")
        let username = self.string(user.username)
        let encryptedUsername = self.string(user.encryptedUsername)
        let password = self.string(user.password)
        let encryptedPassword = self.string(user.encryptedPassword)
        let imageUrl = self.string(user.imageUrl)
        let owner = self.intString("\(user.owner)")
        
        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
        let deepCopyClassPlayer = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLASS_PLAYER, fromContext: ctx, filteredBy: predicate) as! DeepCopyClassPlayer
        
        deepCopyClassPlayer.id = id
        deepCopyClassPlayer.lastName = lastName
        deepCopyClassPlayer.firstName = firstName
        deepCopyClassPlayer.middleName = middleName
        deepCopyClassPlayer.gender = gender
        deepCopyClassPlayer.birthdate = birthdate
        deepCopyClassPlayer.address = address
        deepCopyClassPlayer.mobile = mobile
        deepCopyClassPlayer.email = email
        deepCopyClassPlayer.type = type
        deepCopyClassPlayer.username = username
        deepCopyClassPlayer.encryptedUsername = encryptedUsername
        deepCopyClassPlayer.password = password
        deepCopyClassPlayer.encryptedPassword = encryptedPassword
        deepCopyClassPlayer.imageUrl = imageUrl
        deepCopyClassPlayer.owner = owner
        deepCopyClassPlayer.classId = deepCopyClass.id
        
        var playerIds = self.string(deepCopyClass.playerIds)
        playerIds = "\(playerIds == "" ? "" : "\(playerIds),")\(id)"
        deepCopyClass.addToDeepCopyPlayers(deepCopyClassPlayer)
        deepCopyClass.playerIds = playerIds
    }
    
    /// Creates a copy of clue object in preparation for
    /// creating or updating a clue.
    ///
    /// - parameters:
    ///     - object    : A Clue object
    ///     - type      : An Int64 identifying clue's type
    ///     - owner     : An Int64 identifying clue creator's id
    ///     - isCreation: A Bool identifying selection action (create or update)
    ///     - completion: A completion handler
    func deepCopyClueObject(_ object: Clue?, type: Int64, owner: Int64, isCreation: Bool, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(nil)
            return
        }
        
        let cleared = self.db.clearEntities([ARFConstants.entity.DEEP_COPY_CLUE, ARFConstants.entity.DEEP_COPY_CLUE_CHOICE])
        
        if cleared {
            ctx.performAndWait {
                if isCreation {
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "")
                    let deepCopyClue = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLUE, fromContext: ctx, filteredBy: predicate) as! DeepCopyClue
                    
                    deepCopyClue.id = 0
                    deepCopyClue.type = type
                    deepCopyClue.riddle = ""
                    deepCopyClue.longitude = 0.0
                    deepCopyClue.latitude = 0.0
                    deepCopyClue.locationName = ""
                    deepCopyClue.points = 0
                    deepCopyClue.clue = ""
                    deepCopyClue.owner = owner
                    
                    let related = self.relateChoices(nil, toDeepCopyClue: deepCopyClue, type: type, isCreation: isCreation)
                    let saved = self.db.saveObjectContext(ctx)
                    completion(related && saved ? ["clue": deepCopyClue] : nil)
                }
                else {
                    if let o = object {
                        let id = self.intString("\(o.id)")
                        let aType = self.intString("\(o.type)")
                        let riddle = self.string(o.riddle)
                        let longitude = self.doubleString("\(o.longitude)")
                        let latitude = self.doubleString("\(o.latitude)")
                        let locationName = self.string(o.locationName)
                        let points = self.intString("\(o.points)")
                        let pointsOnAttempts = self.string(o.pointsOnAttempts)
                        let clue = self.string(o.clue)
                        let aOwner = self.intString("\(o.owner)")
                        
                        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                        let deepCopyClue = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLUE, fromContext: ctx, filteredBy: predicate) as! DeepCopyClue
                        
                        deepCopyClue.id = id
                        deepCopyClue.type = aType
                        deepCopyClue.riddle = riddle
                        deepCopyClue.longitude = longitude
                        deepCopyClue.latitude = latitude
                        deepCopyClue.locationName = locationName
                        deepCopyClue.points = points
                        deepCopyClue.pointsOnAttempts = pointsOnAttempts
                        deepCopyClue.clue = clue
                        deepCopyClue.owner = aOwner
                        
                        let splittedPointsOnAttempts = pointsOnAttempts.components(separatedBy: ",")
                        var pointsOnAttemptsFormatted = ""
                        var counter = 0
                        
                        for spoa in splittedPointsOnAttempts {
                            pointsOnAttemptsFormatted = "\(pointsOnAttemptsFormatted == "" ? "" : "\(pointsOnAttemptsFormatted);") [\(counter + 1)] \(spoa)"
                            counter = counter + 1
                        }
                        
                        deepCopyClue.pointsOnAttemptsFormatted = pointsOnAttemptsFormatted
                        
                        var related = false
                        
                        if let choices = o.choices?.allObjects as? [ClueChoice] {
                            related = self.relateChoices(choices, toDeepCopyClue: deepCopyClue, type: type, isCreation: false)
                        }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        completion(related && saved ? ["clue": deepCopyClue] : nil)
                    }
                    else {
                        print("ERROR: Passed clue object is nil!")
                        completion(nil)
                    }
                }
            }
        }
        else {
            print("ERROR: Can't clear deep copy clue entity!")
            completion(nil)
        }
    }
    
    /// Attaches clue choices to deep copy clue.
    ///
    /// - parameters:
    ///     - choices       : An Array identifying list of clue choice objects
    ///     - deepCopyClue  : A DeepCopyClue object
    ///     - type          : An Int64 identifying deep copy clue's type
    ///     - isCreation    : A Bool identifying selection action (create or update)
    fileprivate func relateChoices(_ choices: [ClueChoice]?, toDeepCopyClue deepCopyClue: DeepCopyClue, type: Int64, isCreation: Bool) -> Bool {
        self.prettyFunction()
        
        guard let ctx = deepCopyClue.managedObjectContext else {
            print("ERROR: Can't retrieve deep copy clue context!")
            return false
        }
        
        if isCreation {
            if type == ARFConstants.clueType.MC {
                var counter: Int64 = 0
                var concatChoices = ""
                
                while counter < 4 {
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "\(counter)")
                    let deepCopyClueChoice = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLUE_CHOICE, fromContext: ctx, filteredBy: predicate) as! DeepCopyClueChoice
                    
                    deepCopyClueChoice.id = counter
                    deepCopyClueChoice.clueId = deepCopyClue.id
                    deepCopyClueChoice.choiceStatement = "Choice \(counter + 1)"
                    deepCopyClueChoice.isCorrect = counter == 0 ? 1 : 0
                    deepCopyClueChoice.answer = ""
                    deepCopyClueChoice.encryptedAnswer = ""
                    deepCopyClueChoice.isCaseSensitive = 0
                    
                    let choiceString = "{\"choiceStatement\":\"Choice \(counter + 1)\",\"isCorrect\":\"\(counter == 0 ? 1 : 0)\",\"answer\":\"\(0)\",\"encryptedAnswer\":\"\(0)\",\"isCaseSensitive\":\"\(0)\"}"
                    concatChoices = "\(concatChoices == "" ? "" : "\(concatChoices),")\(choiceString)"
                    deepCopyClue.addToDeepCopyClueChoices(deepCopyClueChoice)
                    
                    counter = counter + 1
                }
                
                deepCopyClue.pointsOnAttempts = "0,0,0,0"
                deepCopyClue.pointsOnAttemptsFormatted = "[1] 0; [2] 0; [3] 0; [4] 0"
                deepCopyClue.choices = "[\(concatChoices)]"
                
                if deepCopyClue.deepCopyClueChoices != nil { return true }
            }
        }
        else {
            if choices != nil {
                var concatChoices = ""
                
                for c in choices! {
                    let id = self.intString("\(c.id)")
                    let clueId = self.intString("\(c.clueId)")
                    let choiceStatement = self.string(c.choiceStatement)
                    let isCorrect = self.intString("\(c.isCorrect)")
                    let answer = self.string(c.answer)
                    let encryptedAnswer = self.string(c.encryptedAnswer)
                    let isCaseSensitive = self.intString("\(c.isCaseSensitive)")
                    
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                    let deepCopyClueChoice = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_CLUE_CHOICE, fromContext: ctx, filteredBy: predicate) as! DeepCopyClueChoice
                    
                    deepCopyClueChoice.id = id
                    deepCopyClueChoice.clueId = clueId
                    deepCopyClueChoice.choiceStatement = choiceStatement
                    deepCopyClueChoice.isCorrect = isCorrect
                    deepCopyClueChoice.answer = answer
                    deepCopyClueChoice.encryptedAnswer = encryptedAnswer
                    deepCopyClueChoice.isCaseSensitive = isCaseSensitive
                    
                    let choiceString = "{\"choiceStatement\":\"\(choiceStatement)\",\"isCorrect\":\"\(isCorrect)\",\"answer\":\"\(answer)\",\"encryptedAnswer\":\"\(encryptedAnswer)\",\"isCaseSensitive\":\"\(isCaseSensitive)\"}"
                    concatChoices = "\(concatChoices == "" ? "" : "\(concatChoices),")\(choiceString)"
                    deepCopyClue.addToDeepCopyClueChoices(deepCopyClueChoice)
                }
                
                deepCopyClue.choices = "[\(concatChoices)]"
                
                if deepCopyClue.deepCopyClueChoices != nil { return true }
            }
        }
        
        return false
    }
    
    /// Assembles deep copy choices and as a string and
    /// attaches it to deep copy clue and and saves to
    /// core data.
    ///
    /// - parameters:
    ///     - deepCopyClue  : A DeepCopyClue object
    ///     - completion    : A completion handler
    func assembleChoicesString(forDeepCopyClue deepCopyClue: DeepCopyClue, completion: @escaping ARFDMDoneBlock) {
        guard let ctx = deepCopyClue.managedObjectContext else {
            print("ERROR: Cant' retrieve deep copy clue managed object context!")
            completion(false)
            return
        }
        
        guard let set = deepCopyClue.deepCopyClueChoices, let deepCopyClueChoices = set.allObjects as? [DeepCopyClueChoice]  else {
            print("ERROR: Cant' retrieve deep copy clue choice object!")
            completion(false)
            return
        }
        
        var concatChoices = ""
        
        ctx.performAndWait {
            for d in deepCopyClueChoices {
                let choiceStatement = self.string(d.choiceStatement)
                let isCorrect = self.string(d.isCorrect)
                let answer = self.string(d.answer)
                let encryptedAnswer = self.string(d.encryptedAnswer)
                let isCaseSensitive = self.string(d.isCaseSensitive)
                
                let choiceString = "{\"choiceStatement\":\"\(choiceStatement)\",\"isCorrect\":\"\(isCorrect)\",\"answer\":\"\(answer)\",\"encryptedAnswer\":\"\(encryptedAnswer)\",\"isCaseSensitive\":\"\(isCaseSensitive)\"}"
                concatChoices = "\(concatChoices == "" ? "" : "\(concatChoices),")\(choiceString)"
            }
            
            deepCopyClue.choices = "[\(concatChoices)]"
            let saved = self.db.saveObjectContext(ctx)
            completion(saved)
        }
    }
    
    /// Assembles deep copy choices and as a string and
    /// Checks if each choice contains statement and if
    /// there is at least one correct answer.
    ///
    /// - parameter deepCopyClue: A DeepCopyClue object
    func isMultipleChoiceValid(forDeepCopyClue deepCopyClue: DeepCopyClue) -> Bool {
        guard let set = deepCopyClue.deepCopyClueChoices, let deepCopyClueChoices = set.allObjects as? [DeepCopyClueChoice]  else {
            print("ERROR: Cant' retrieve deep copy clue choice object!")
            return false
        }
        
        var inCorrectCount = 0
        
        for d in deepCopyClueChoices {
            let choiceStatement = self.string(d.choiceStatement)
            let isCorrect = self.string(d.isCorrect)
            if choiceStatement == "" { return false }
            if isCorrect == "0" { inCorrectCount = inCorrectCount + 1 }
        }
        
        if inCorrectCount >= deepCopyClueChoices.count { return false }
        
        return true
    }
    
    /// Creates a copy of treasure object in preparation for
    /// creating or updating a treasure.
    ///
    /// - parameters:
    ///     - object    : A Treasure object
    ///     - owner     : An Int64 identifying treasure creator's id
    ///     - isCreation: A Bool identifying selection action (create or update)
    ///     - completion: A completion handler
    func deepCopyTreasureObject(_ object: Treasure?, owner: Int64, isCreation: Bool, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(nil)
            return
        }
        
        let cleared = self.db.clearEntities([ARFConstants.entity.DEEP_COPY_TREASURE])
        
        if cleared {
            ctx.performAndWait {
                if isCreation {
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "")
                    let deepCopyTreasure = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_TREASURE, fromContext: ctx, filteredBy: predicate) as! DeepCopyTreasure
                    
                    deepCopyTreasure.id = 0
                    deepCopyTreasure.name = ""
                    deepCopyTreasure.treasureDescription = ""
                    deepCopyTreasure.imageUrl = ""
                    deepCopyTreasure.imageLocalName = ""
                    deepCopyTreasure.imageData = nil
                    deepCopyTreasure.model3dUrl = ""
                    deepCopyTreasure.model3dLocalName = ""
                    deepCopyTreasure.model3dData = nil
                    deepCopyTreasure.claimingQuestion = ""
                    deepCopyTreasure.claimingAnswers = ""
                    deepCopyTreasure.encryptedClaimingAnswers = ""
                    deepCopyTreasure.isCaseSensitive = 0
                    deepCopyTreasure.longitude = 0
                    deepCopyTreasure.latitude = 0
                    deepCopyTreasure.locationName = ""
                    deepCopyTreasure.points = 0
                    deepCopyTreasure.owner = owner
                    
                    let saved = self.db.saveObjectContext(ctx)
                    completion(saved ? ["treasure": deepCopyTreasure] : nil)
                }
                else {
                    if let o = object {
                        let id = self.intString("\(o.id)")
                        let name = self.string(o.name)
                        let treasureDescription = self.string(o.treasureDescription)
                        let imageUrl = self.string(o.imageUrl)
                        let imageLocalName = self.string(o.imageLocalName)
                        let model3dUrl = self.string(o.model3dUrl)
                        let model3dLocalName = self.string(o.model3dLocalName)
                        let claimingQuestion = self.string(o.claimingQuestion)
                        let claimingAnswers = self.string(o.claimingAnswers)
                        let encryptedClaimingAnswers = self.string(o.encryptedClaimingAnswers)
                        let isCaseSensitive = self.intString("\(o.isCaseSensitive)")
                        let longitude = self.doubleString("\(o.longitude)")
                        let latitude = self.doubleString("\(o.latitude)")
                        let locationName = self.string(o.locationName)
                        let points = self.intString("\(o.points)")
                        let owner = self.intString("\(o.owner)")
                        
                        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                        let deepCopyTreasure = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_TREASURE, fromContext: ctx, filteredBy: predicate) as! DeepCopyTreasure
                        
                        deepCopyTreasure.id = id
                        deepCopyTreasure.name = name
                        deepCopyTreasure.treasureDescription = treasureDescription
                        deepCopyTreasure.imageUrl = imageUrl
                        deepCopyTreasure.imageLocalName = imageLocalName
                        deepCopyTreasure.imageData = nil
                        deepCopyTreasure.model3dUrl = model3dUrl
                        deepCopyTreasure.model3dLocalName = model3dLocalName
                        deepCopyTreasure.model3dData = nil
                        deepCopyTreasure.claimingQuestion = claimingQuestion
                        deepCopyTreasure.claimingAnswers = claimingAnswers
                        deepCopyTreasure.encryptedClaimingAnswers = encryptedClaimingAnswers
                        deepCopyTreasure.isCaseSensitive = isCaseSensitive
                        deepCopyTreasure.longitude = longitude
                        deepCopyTreasure.latitude = latitude
                        deepCopyTreasure.locationName = locationName
                        deepCopyTreasure.points = points
                        deepCopyTreasure.owner = owner
                        
                        let saved = self.db.saveObjectContext(ctx)
                        completion(saved ? ["treasure": deepCopyTreasure] : nil)
                    }
                    else {
                        print("ERROR: Passed treasure object is nil!")
                        completion(nil)
                    }
                }
            }
        }
        else {
            print("ERROR: Can't clear deep copy treasure entity!")
            completion(nil)
        }
    }
    
    /// Creates a copy of game object in preparation for
    /// creating or updating a game.
    ///
    /// - parameters:
    ///     - object    : A Game object
    ///     - owner     : An Int64 identifying game creator's id
    ///     - isCreation: A Bool identifying selection action (create or update)
    ///     - completion: A completion handler
    func deepCopyGameObject(_ object: Game?, owner: Int64, isCreation: Bool, completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(nil)
            return
        }
        
        let cleared = self.db.clearEntities([ARFConstants.entity.DEEP_COPY_GAME,
                                             ARFConstants.entity.DEEP_COPY_GAME_TREASURE,
                                             ARFConstants.entity.DEEP_COPY_GAME_CLUE,
                                             ARFConstants.entity.DEEP_COPY_GAME_CLUE_CHOICE])
        
        if cleared {
            ctx.performAndWait {
                if isCreation {
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "")
                    let deepCopyGame = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_GAME, fromContext: ctx, filteredBy: predicate) as! DeepCopyGame
                    
                    let defaultStartDate = self.date(fromString: "\(Date())", format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                    let defaultEndDate = self.addDays(1, toDate: defaultStartDate)
                    
                    deepCopyGame.id = 0
                    deepCopyGame.name = ""
                    deepCopyGame.discussion = ""
                    deepCopyGame.isTimeBound = 0
                    deepCopyGame.minutes = 5
                    deepCopyGame.isNoExpiration = 1
                    deepCopyGame.start = defaultStartDate
                    deepCopyGame.end = defaultEndDate
                    deepCopyGame.isSecure = 0
                    deepCopyGame.securityCode = ""
                    deepCopyGame.encryptedSecurityCode = ""
                    deepCopyGame.startingClueId = 0
                    deepCopyGame.startingClueName = ""
                    deepCopyGame.owner = owner
                    deepCopyGame.clueIds = ""
                    deepCopyGame.treasureId = 0
                    deepCopyGame.treasureName = ""
                    deepCopyGame.treasurePoints = 0
                    deepCopyGame.totalPoints = 0
                    
                    let saved = self.db.saveObjectContext(ctx)
                    completion(saved ? ["game": deepCopyGame] : nil)
                }
                else {
                    if let o = object {
                        let id = self.intString("\(o.id)")
                        let name = self.string(o.name)
                        let discussion = self.string(o.discussion)
                        let isTimeBound = self.intString("\(o.isTimeBound)")
                        let minutes = self.intString("\(o.minutes)")
                        let isNoExpiration = self.intString("\(o.isNoExpiration)")
                        let start = self.string(o.start)
                        let end = self.string(o.end)
                        let isSecure = self.intString("\(o.isSecure)")
                        let securityCode = self.string(o.securityCode)
                        let encryptedSecurityCode = self.string(o.encryptedSecurityCode)
                        let startingClueId = self.intString("\(o.startingClueId)")
                        let startingClueName = self.string(o.startingClueName)
                        let aOwner = self.intString("\(o.owner)")
                        
                        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                        let deepCopyGame = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_GAME, fromContext: ctx, filteredBy: predicate) as! DeepCopyGame
                        
                        let defaultStartDate = self.date(fromString: "\(Date())", format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                        let startDate = self.date(fromString: start, format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                        let defaultEndDate = self.addDays(1, toDate: defaultStartDate)
                        let endDate = self.date(fromString: end, format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                        
                        deepCopyGame.id = id
                        deepCopyGame.name = name
                        deepCopyGame.discussion = discussion
                        deepCopyGame.totalPoints = 0
                        deepCopyGame.isTimeBound = isTimeBound
                        deepCopyGame.minutes = minutes
                        deepCopyGame.isNoExpiration = isNoExpiration
                        deepCopyGame.start = start == "" ? defaultStartDate : startDate
                        deepCopyGame.end = end == "" ? defaultEndDate : endDate
                        deepCopyGame.isSecure = isSecure
                        deepCopyGame.securityCode = securityCode
                        deepCopyGame.encryptedSecurityCode = encryptedSecurityCode
                        deepCopyGame.startingClueId = startingClueId
                        deepCopyGame.startingClueName = startingClueName
                        deepCopyGame.owner = aOwner
                        deepCopyGame.clueIds = ""
                        deepCopyGame.treasureId = 0
                        deepCopyGame.treasureName = ""
                        deepCopyGame.treasurePoints = 0
                        
                        // Relate game treasure to deep copy game
                        if let gameTreasure = o.treasure { self.relateGameTreasure(gameTreasure, toDeepCopyGame: deepCopyGame) }
                        
                        // Relage game clues to deep copy game
                        if let gameClues = o.clues?.allObjects as? [GameClue] { self.relateGameClues(gameClues, toDeepCopyGame: deepCopyGame) }
                        
                        let saved = self.db.saveObjectContext(ctx)
                        completion(saved ? ["game": deepCopyGame] : nil)
                    }
                    else {
                        print("ERROR: Passed game object is nil!")
                        completion(nil)
                    }
                }
            }
        }
        else {
            print("ERROR: Can't clear deep copy game entity!")
            completion(nil)
        }
    }
    
    /// Attaches game treasure to deep copy game.
    ///
    /// - parameters:
    ///     - gameTreasure: A GameTreasure object
    ///     - deepCopyGame: A DeepCopyGame object
    fileprivate func relateGameTreasure(_ gameTreasure: GameTreasure, toDeepCopyGame deepCopyGame: DeepCopyGame) {
        self.prettyFunction()
        
        guard let ctx = deepCopyGame.managedObjectContext else {
            print("ERROR: Can't retrieve deep copy game context!")
            return
        }

        let id = self.intString(self.string(gameTreasure.id))
        let name = self.string(gameTreasure.name)
        let treasureDescription = self.string(gameTreasure.treasureDescription)
        let imageUrl = self.string(gameTreasure.imageUrl)
        let imageLocalName = self.string(gameTreasure.imageLocalName)
        let model3dUrl = self.string(gameTreasure.model3dUrl)
        let model3dLocalName = self.string(gameTreasure.model3dLocalName)
        let claimingQuestion = self.string(gameTreasure.claimingQuestion)
        let claimingAnswers = self.string(gameTreasure.claimingAnswers)
        let encryptedClaimingAnswers = self.string(gameTreasure.encryptedClaimingAnswers)
        let isCaseSensitive = self.intString(self.string(gameTreasure.isCaseSensitive))
        let longitude = self.doubleString(self.string(gameTreasure.longitude))
        let latitude = self.doubleString(self.string(gameTreasure.latitude))
        let locationName = self.string(gameTreasure.locationName)
        let points = self.intString(self.string(gameTreasure.points))
        let owner = self.intString(self.string(gameTreasure.owner))
        
        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
        let deepCopyGameTreasure = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_GAME_TREASURE, fromContext: ctx, filteredBy: predicate) as! DeepCopyGameTreasure
        
        deepCopyGameTreasure.id = id
        deepCopyGameTreasure.name = name
        deepCopyGameTreasure.treasureDescription = treasureDescription
        deepCopyGameTreasure.imageUrl = imageUrl
        deepCopyGameTreasure.imageLocalName = imageLocalName
        deepCopyGameTreasure.model3dUrl = model3dUrl
        deepCopyGameTreasure.model3dLocalName = model3dLocalName
        deepCopyGameTreasure.claimingQuestion = claimingQuestion
        deepCopyGameTreasure.claimingAnswers = claimingAnswers
        deepCopyGameTreasure.encryptedClaimingAnswers = encryptedClaimingAnswers
        deepCopyGameTreasure.isCaseSensitive = isCaseSensitive
        deepCopyGameTreasure.longitude = longitude
        deepCopyGameTreasure.latitude = latitude
        deepCopyGameTreasure.locationName = locationName
        deepCopyGameTreasure.points = points
        deepCopyGameTreasure.owner = owner
        deepCopyGameTreasure.gameId = deepCopyGame.id
        
        deepCopyGame.deepCopyGameTreasure = deepCopyGameTreasure
        deepCopyGame.treasureId = id
        deepCopyGame.treasureName = name
        deepCopyGame.treasurePoints = points
        deepCopyGame.totalPoints = deepCopyGame.totalPoints + points
    }
    
    /// Attaches game clues to deep copy game.
    ///
    /// - parameters:
    ///     - gameClues     : An array of GameClue objects
    ///     - deepCopyGame  : A DeepCopyGame object
    fileprivate func relateGameClues(_ gameClues: [GameClue], toDeepCopyGame deepCopyGame: DeepCopyGame) {
        self.prettyFunction()
        
        guard let ctx = deepCopyGame.managedObjectContext else {
            print("ERROR: Can't retrieve deep copy game context!")
            return
        }
        
        var clueIds = ""
        var accumulatedPoints: Int64 = 0
        var didStartingClueExist = false
        
        for gc in gameClues {
            let id = self.intString(self.string(gc.id))
            let type = self.intString(self.string(gc.type))
            let riddle = self.string(gc.riddle)
            let longitude = self.doubleString(self.string(gc.longitude))
            let latitude = self.doubleString(self.string(gc.latitude))
            let locationName = self.string(gc.locationName)
            let points = self.intString(self.string(gc.points))
            let pointsOnAttempts = self.string(gc.pointsOnAttempts)
            let clue = self.string(gc.clue)
            let owner = self.intString(self.string(gc.owner))
            
            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
            let deepCopyGameClue = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_GAME_CLUE, fromContext: ctx, filteredBy: predicate) as! DeepCopyGameClue
            
            deepCopyGameClue.id = id
            deepCopyGameClue.type = type
            deepCopyGameClue.riddle = riddle
            deepCopyGameClue.longitude = longitude
            deepCopyGameClue.latitude = latitude
            deepCopyGameClue.locationName = locationName
            deepCopyGameClue.points = points
            deepCopyGameClue.pointsOnAttempts = pointsOnAttempts
            deepCopyGameClue.clue = clue
            deepCopyGameClue.owner = owner
            deepCopyGameClue.gameId = deepCopyGame.id
            
            clueIds = "\(clueIds == "" ? "" : "\(clueIds),")\(id)"
            accumulatedPoints = accumulatedPoints + points
            
            // Check if there's a starting clue
            if deepCopyGame.startingClueId == id { didStartingClueExist = true }
            
            // Relate game clue choices to deep copy game clue
            if let gameClueChoices = gc.choices?.allObjects as? [GameClueChoice] {
                self.relateGameClueChoices(gameClueChoices, toDeepCopyGameClue: deepCopyGameClue)
            }
            
            deepCopyGame.addToDeepCopyGameClues(deepCopyGameClue)
        }
        
        deepCopyGame.clueIds = clueIds
        deepCopyGame.totalPoints = deepCopyGame.totalPoints + accumulatedPoints
        
        if !didStartingClueExist {
            deepCopyGame.startingClueId = 0
            deepCopyGame.startingClueName = ""
        }
    }
    
    /// Attaches game clue choices to deep copy game clue.
    ///
    /// - parameters:
    ///     - gameClueChoices   : An array of GameClueChoice objects
    ///     - deepCopyGameClue  : A DeepCopyGameClue object
    fileprivate func relateGameClueChoices(_ gameClueChoices: [GameClueChoice], toDeepCopyGameClue deepCopyGameClue: DeepCopyGameClue) {
        self.prettyFunction()
        
        guard let ctx = deepCopyGameClue.managedObjectContext else {
            print("ERROR: Can't retrieve deep copy game clue context!")
            return
        }
        
        for gcc in gameClueChoices {
            let id = self.intString(self.string(gcc.id))
            let clueId = self.intString(self.string(gcc.clueId))
            let choiceStatement = self.string(gcc.choiceStatement)
            let isCorrect = self.intString(self.string(gcc.isCorrect))
            let answer = self.string(gcc.answer)
            let encryptedAnswer = self.string(gcc.encryptedAnswer)
            let isCaseSensitive = self.intString(self.string(gcc.isCaseSensitive))
            
            let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
            let deepCopyGameClueChoice = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_GAME_CLUE_CHOICE, fromContext: ctx, filteredBy: predicate) as! DeepCopyGameClueChoice
            
            deepCopyGameClueChoice.id = id
            deepCopyGameClueChoice.clueId = clueId
            deepCopyGameClueChoice.choiceStatement = choiceStatement
            deepCopyGameClueChoice.isCorrect = isCorrect
            deepCopyGameClueChoice.answer = answer
            deepCopyGameClueChoice.encryptedAnswer = encryptedAnswer
            deepCopyGameClueChoice.isCaseSensitive = isCaseSensitive
            deepCopyGameClueChoice.gameId = deepCopyGameClue.gameId
            
            deepCopyGameClue.addToDeepCopyGameClueChoices(deepCopyGameClueChoice)
        }
    }
    
    /// Attaches treasure to deep copy game.
    ///
    /// - parameters:
    ///     - treasureId: An Int64 identifying treasure id
    ///     - gameId    : An Int64 identifying game id
    ///     - completion: A completion handler
    func relateTreasure(withId treasureId: Int64, toDeepCopyGameWithId gameId: Int64, completion: @escaping ARFDMDoneBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(false)
            return
        }
        
        ctx.performAndWait {
            let predicateA = self.predicate(forKeyPath: "id", exactValue: "\(gameId)")
            
            guard let deepCopyGame = self.db.retrieveObject(forEntity: ARFConstants.entity.DEEP_COPY_GAME, filteredBy: predicateA) as? DeepCopyGame else {
                print("ERROR: Can't retrieve deep copy game!")
                completion(false)
                return
            }
            
            let cleared = self.db.clearEntities([ARFConstants.entity.DEEP_COPY_GAME_TREASURE])
            
            if cleared {
                let predicateB = self.predicate(forKeyPath: "id", exactValue: "\(treasureId)")
                
                if let treasure = self.db.retrieveObject(forEntity: ARFConstants.entity.TREASURE, filteredBy: predicateB) as? Treasure {
                    let id = self.intString("\(treasure.id)")
                    let name = self.string(treasure.name)
                    let treasureDescription = self.string(treasure.treasureDescription)
                    let imageUrl = self.string(treasure.imageUrl)
                    let imageLocalName = self.string(treasure.imageLocalName)
                    let model3dUrl = self.string(treasure.model3dUrl)
                    let model3dLocalName = self.string(treasure.model3dLocalName)
                    let claimingQuestion = self.string(treasure.claimingQuestion)
                    let claimingAnswers = self.string(treasure.claimingAnswers)
                    let encryptedClaimingAnswers = self.string(treasure.encryptedClaimingAnswers)
                    let isCaseSensitive = self.intString("\(treasure.isCaseSensitive)")
                    let longitude = self.doubleString(self.string(treasure.longitude))
                    let latitude = self.doubleString(self.string(treasure.latitude))
                    let locationName = self.string(treasure.locationName)
                    let points = self.intString("\(treasure.points)")
                    let owner = self.intString("\(treasure.owner)")
                    
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                    let deepCopyGameTreasure = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_GAME_TREASURE, fromContext: ctx, filteredBy: predicate) as! DeepCopyGameTreasure
   
                    deepCopyGameTreasure.id = id
                    deepCopyGameTreasure.name = name
                    deepCopyGameTreasure.treasureDescription = treasureDescription
                    deepCopyGameTreasure.imageUrl = imageUrl
                    deepCopyGameTreasure.imageLocalName = imageLocalName
                    deepCopyGameTreasure.model3dUrl = model3dUrl
                    deepCopyGameTreasure.model3dLocalName = model3dLocalName
                    deepCopyGameTreasure.claimingQuestion = claimingQuestion
                    deepCopyGameTreasure.claimingAnswers = claimingAnswers
                    deepCopyGameTreasure.encryptedClaimingAnswers = encryptedClaimingAnswers
                    deepCopyGameTreasure.isCaseSensitive = isCaseSensitive
                    deepCopyGameTreasure.longitude = longitude
                    deepCopyGameTreasure.latitude = latitude
                    deepCopyGameTreasure.locationName = locationName
                    deepCopyGameTreasure.points = points
                    deepCopyGameTreasure.owner = owner
                    
                    deepCopyGame.treasureId = id
                    deepCopyGame.treasureName = name
                    deepCopyGame.treasurePoints = points
                    deepCopyGame.totalPoints = deepCopyGame.totalPoints + points
                    deepCopyGame.deepCopyGameTreasure = deepCopyGameTreasure
                }
                
                let saved = self.db.saveObjectContext(ctx)
                completion(saved)
            }
            else {
                completion(false)
            }
        }
    }
    
    /// Attaches clues to deep copy game.
    ///
    /// - parameters:
    ///     - ids       : Array of Int64 identifying clue ids
    ///     - gameId    : An Int64 identifying game id
    ///     - completion: A completion handler
    func relateClues(withIds ids: [Int64], toDeepCopyGameWithId gameId: Int64, completion: @escaping ARFDMDoneBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(false)
            return
        }
        
        ctx.performAndWait {
            let predicateA = self.predicate(forKeyPath: "id", exactValue: "\(gameId)")
            
            guard let deepCopyGame = self.db.retrieveObject(forEntity: ARFConstants.entity.DEEP_COPY_GAME, filteredBy: predicateA) as? DeepCopyGame else {
                print("ERROR: Can't retrieve deep copy game!")
                completion(false)
                return
            }
            
            let cleared = self.db.clearEntities([ARFConstants.entity.DEEP_COPY_GAME_CLUE])
            deepCopyGame.clueIds = ""
            deepCopyGame.totalPoints = deepCopyGame.treasurePoints
            
            if cleared {
                for id in ids {
                    let predicateB = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                    if let clue = self.db.retrieveObject(forEntity: ARFConstants.entity.CLUE, filteredBy: predicateB) as? Clue {
                        self.relateClue(clue, toDeepCopyGame: deepCopyGame)
                    }
                }
                
                let saved = self.db.saveObjectContext(ctx)
                completion(saved)
            }
            else {
                completion(false)
            }
        }
    }
    
    /// Attaches game clue to deep copy game.
    ///
    /// - parameters:
    ///     - clue          : A Clue object
    ///     - deepCopyGame  : A DeepCopyGame object
    fileprivate func relateClue(_ clue: Clue, toDeepCopyGame deepCopyGame: DeepCopyGame) {
        self.prettyFunction()
        
        guard let ctx = deepCopyGame.managedObjectContext else {
            print("ERROR: Can't retrieve deep copy game context!")
            return
        }
        
        let id = self.intString("\(clue.id)")
        let type = self.intString("\(clue.type)")
        let riddle = self.string(clue.riddle)
        let longitude = self.doubleString(self.string(clue.longitude))
        let latitude = self.doubleString(self.string(clue.latitude))
        let locationName = self.string(clue.locationName)
        let points = self.intString("\(clue.points)")
        let pointsOnAttempts = self.string(clue.pointsOnAttempts)
        let clue = self.string(clue.clue)

        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
        let deepCopyGameClue = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_GAME_CLUE, fromContext: ctx, filteredBy: predicate) as! DeepCopyGameClue
        
        deepCopyGameClue.id = id
        deepCopyGameClue.type = type
        deepCopyGameClue.riddle = riddle
        deepCopyGameClue.longitude = longitude
        deepCopyGameClue.latitude = latitude
        deepCopyGameClue.locationName = locationName
        deepCopyGameClue.points = points
        deepCopyGameClue.pointsOnAttempts = pointsOnAttempts
        deepCopyGameClue.clue = clue
        deepCopyGameClue.gameId = deepCopyGame.id
        
        var clueIds = self.string(deepCopyGame.clueIds!)
        clueIds = "\(clueIds == "" ? "" : "\(clueIds),")\(id)"
        deepCopyGame.addToDeepCopyGameClues(deepCopyGameClue)
        deepCopyGame.clueIds = clueIds
        deepCopyGame.totalPoints = deepCopyGame.totalPoints + points
    }
    
    /// Creates a copy of sidekick object in preparation
    /// for creating or updating a sidekick.
    ///
    /// - parameters:
    ///     - object    : A Sidekick object
    ///     - owner     : An Int64 identifying player's id
    ///     - isCreation: A Bool identifying selection action (create or update)
    ///     - completion: A completion handler
    func deepCopySidekickObject(_ object: Sidekick?, owner: Int64, isCreation: Bool, name: String = "", completion: @escaping ARFDMDataBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(nil)
            return
        }
        
        let cleared = self.db.clearEntities([ARFConstants.entity.DEEP_COPY_SIDEKICK])
        
        if cleared {
            ctx.performAndWait {
                if isCreation {
                    let predicate = self.predicate(forKeyPath: "id", exactValue: "")
                    let deepCopySidekick = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_SIDEKICK, fromContext: ctx, filteredBy: predicate) as! DeepCopySidekick
                    
                    deepCopySidekick.id = 0
                    deepCopySidekick.type = 0
                    deepCopySidekick.name = name
                    deepCopySidekick.level = 1
                    deepCopySidekick.points = 0
                    deepCopySidekick.ownedBy = owner
                    
                    let saved = self.db.saveObjectContext(ctx)
                    completion(saved ? ["sidekick": deepCopySidekick] : nil)
                }
                else {
                    if let o = object {
                        let id = self.intString("\(o.id)")
                        let type = self.intString("\(o.type)")
                        let name = self.string(o.name)
                        let level = self.intString("\(o.level)")
                        let points = self.intString("\(o.points)")
                        let ownedBy = self.intString("\(o.ownedBy)")
                        
                        let predicate = self.predicate(forKeyPath: "id", exactValue: "\(id)")
                        let deepCopySidekick = self.db.retrieveEntity(ARFConstants.entity.DEEP_COPY_SIDEKICK, fromContext: ctx, filteredBy: predicate) as! DeepCopySidekick
                        
                        deepCopySidekick.id = id
                        deepCopySidekick.type = type
                        deepCopySidekick.name = name
                        deepCopySidekick.level = level
                        deepCopySidekick.points = points
                        deepCopySidekick.ownedBy = ownedBy
                        
                        let saved = self.db.saveObjectContext(ctx)
                        completion(saved ? ["sidekick": deepCopySidekick] : nil)
                    }
                    else {
                        print("ERROR: Passed sidekick object is nil!")
                        completion(nil)
                    }
                }
            }
        }
        else {
            print("ERROR: Can't clear deep copy sidekick entity!")
            completion(nil)
        }
    }
    
    // MARK: - Posting Helpers
    
    /// Checks if objects of entity contains empty value for
    /// required keys.
    ///
    /// - parameters:
    ///     - entity    : A String identifying core data entity
    ///     - predicate : A NSPredicate identifying filter
    ///     - rvKeys    : An array of String
    func doesEntity(_ entity: String, filteredBy predicate: NSPredicate, containsEmptyValueForRequiredKeys rvKeys: [String]) -> Bool {
        self.prettyFunction()
        
        guard let object = self.db.retrieveObject(forEntity: entity, filteredBy: predicate) else {
            print("ERROR: Can't retrieve object from core data!")
            return true
        }
     
        let objKeys = object.entity.attributesByName.keys
        
        for k in objKeys {
            if rvKeys.contains(k) {
                let value = self.string(object.value(forKey: k))
                if value == "" { return true }
            }
        }
        
        return false
    }
    
    /// Assembles data from deep copy object for server
    /// request's body.
    ///
    /// - parameters:
    ///     - entity        : A String identifying core data entity
    ///     - predicate     : A NSPredicate identifying filter
    ///     - requiredKeys  : An array of String
    func assemblePostData(fromEntity entity: String, filteredBy predicate: NSPredicate, requiredKeys: [String]) -> [String: Any]? {
        self.prettyFunction()
        
        guard let object = self.db.retrieveObject(forEntity: entity, filteredBy: predicate) else {
            print("ERROR: Can't retrieve object from core data!")
            return nil
        }
    
        let objKeys = object.entity.attributesByName.keys
        var data = [String: Any]()
        
        for k in objKeys {
            if requiredKeys.contains(k) {
                let value = self.string(object.value(forKey: k))
                data[k] = value
            }
        }
        
        return data.count > 0 ? data : nil
    }
    
    /// Assembles data for game result.
    ///
    /// - parameter gameId: A String identifying game's id
    fileprivate func assembleGameResultPostData(forGameWithId gameId: String) -> [String: Any]? {
        self.prettyFunction()
        
        let entityClue = ARFConstants.entity.GAME_CLUE
        let predicateClue = self.predicate(forKeyPath: "gpGameId", exactValue: gameId)
        
        guard let clueObjects = self.db.retrieveObjects(forEntity: entityClue, filteredBy: predicateClue) as? [GameClue] else {
            print("ERROR: Can't retrieve game clue objects from core data!")
            return nil
        }
        
        let entityTreasure = ARFConstants.entity.GAME_TREASURE
        let predicateTreasure = self.predicate(forKeyPath: "gpGameId", exactValue: gameId)
        
        guard let treasureObject = self.db.retrieveObject(forEntity: entityTreasure, filteredBy: predicateTreasure) as? GameTreasure else {
            print("ERROR: Can't retrieve game treasure object from core data!")
            return nil
        }
        
        var clues = ""
        var classId = ""
        
        for clue in clueObjects {
            let cluestring = "{\"classId\":\"\(clue.gpClassId ?? "")\",\"playerId\":\"\(clue.gpPlayerId ?? "")\",\"playerName\":\"\(clue.gpPlayerName ?? "")\",\"gameId\":\"\(clue.gpGameId ?? "")\",\"clueId\":\"\(clue.gpClueId ?? "")\",\"numberOfAttempts\":\"\(clue.gpNumberOfAttempts ?? "")\",\"points\":\"\(clue.gpPoints ?? "")\"}"
            clues = "\(clues == "" ? "" : "\(clues),")\(cluestring)"
            classId = clue.gpClassId ?? ""
        }
     
        classId = treasureObject.gpClassId ?? classId
        
        let playerId = treasureObject.gpPlayerId ?? "\(self.loggedUserId)"
        let playerName = treasureObject.gpPlayerName ?? self.loggedUserFullName
        let tGameId = treasureObject.gpGameId ?? gameId
        let treasureId = treasureObject.gpTreasureId ?? "\(treasureObject.id)"
        let treasureName = treasureObject.gpTreasureName ?? treasureObject.name ?? ""
        let numberOfAttempts = treasureObject.gpNumberOfAttempts ?? "0"
        let points = treasureObject.gpPoints ?? "0"
        
        let treasure = "[{\"classId\":\"\(classId)\",\"playerId\":\"\(playerId)\",\"playerName\":\"\(playerName)\",\"gameId\":\"\(tGameId)\",\"treasureId\":\"\(treasureId)\",\"treasureName\":\"\(treasureName)\",\"numberOfAttempts\":\"\(numberOfAttempts)\",\"points\":\"\(points)\"}]"

        let postData: [String: Any] = ["clues": "[\(clues)]", "treasure": treasure]
        return postData
    }
    
    // MARK: - Saving Files in Core Data
    
    /// Save details of each file in core data.
    ///
    /// - parameters:
    ///     - files     : An array of file details
    ///     - completion: A completion handler
    func saveFiles(_ files: [[String: Any]], completion: ARFDMDoneBlock) {
        self.prettyFunction()
        
        guard let ctx = self.db.retrieveObjectWorkerContext() else {
            print("ERROR: Can't retrieve worker context!")
            completion(false)
            return
        }
        
        let cleared = self.db.clearEntities([ARFConstants.entity.FILE])
        
        if cleared {
            ctx.performAndWait {
                for file in files {
                    let fsfn = self.intString("\(file["fsfn"] ?? 0)")
                    let sdui = self.string(file["sdui"])
                    let name = self.string(file["name"])
                    let type = self.string(file["type"])
                    let path = self.string(file["path"])
                    let size = self.intString("\(file["size"] ?? 0)")
                    let date = self.string(file["date"])
                    
                    let predicate = self.predicate(forKeyPath: "fsfn", exactValue: "\(fsfn)")
                    let fileObject = self.db.retrieveEntity(ARFConstants.entity.FILE, fromContext: ctx, filteredBy: predicate) as! File
                    
                    fileObject.fsfn = fsfn
                    fileObject.sdui = sdui
                    fileObject.name = name
                    fileObject.type = type
                    fileObject.path = path
                    fileObject.size = size
                    fileObject.date = self.date(fromString: date, format: ARFConstants.timeFormat.CLIENT_DEFAULT)
                }
                
                let saved = self.db.saveObjectContext(ctx)
                completion(saved)
            }
        }
        else {
            print("ERROR: Can't clear file entity!")
            completion(false)
        }
    }
    
    // MARK: - Game Play Status
    
    /// Determines if game has already been finished or if
    /// there is only one clue left.
    ///
    /// - parameter gameId: A String identifying game's id
    func getStatusOfGame(withId gameId: String) -> (Bool, Bool) {
        self.prettyFunction()
        
        let entityGame = ARFConstants.entity.GAME
        let predicateGame = self.predicate(forKeyPath: "id", exactValue: gameId)

        guard let game = self.db.retrieveObject(forEntity: entityGame, filteredBy: predicateGame) as? Game else {
            print("ERROR: Can't retrieve game object!")
            return (false, false)
        }
        
        guard let set = game.clues, let clues = set.allObjects as? [GameClue] else {
            print("ERROR: Can't retrieve game clue objects!")
            return (false, false)
        }
        
        var count = 0
        
        for clue in clues {
            let isDone = clue.gpIsDone ?? "0"
            if isDone == "0" { count = count + 1 }
        }
        
 
        return (count == 0 ? true : false, count == 1 ? true : false)
    }
    
    // MARK: - Debugging Helper
    
    /// Prints out function's details for debugging purposes.
    ///
    /// - parameters:
    ///     - file      : A String identifying the name of
    ///                   the file in which it appears
    ///     - function  : A String identifying the name of
    ///                   the declaration in which it appears
    ///     - line      : An Int identifying the line number
    ///                   on which it appears
    fileprivate func prettyFunction(_ file: NSString = #file, function: String = #function, line: Int = #line) {
        print("<start>--- file: \(file.lastPathComponent) function:\(function) line:\(line) ---<end>")
    }
    
}

