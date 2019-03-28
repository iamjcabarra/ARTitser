//
//  ARFServerRequestHelper.swift
//  ARFollow
//
//  Created by Julius Abarra on 12/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import Foundation

protocol NetworkProtocol {
    func buildURL(fromRequestEndPoint endPoint: NSString) -> URL?
    func buildURLRequest(forMethod method: String, fromUrl url: URL, withBody body: AnyObject?) -> URLRequest
    func buildPostFormDataURLRequest(fromUrl url: URL, withBody body: AnyObject) -> URLRequest
    func buildPostFormDataURLRequest(fromUrl url: URL, withParameters parameters: [String: Any], imageKey: String, andImageData imageData: Data) -> URLRequest
    func buildPostFormDataURLRequest(fromUrl url: URL, withParameters parameters: [String: Any], imageKey: String, imageData: Data, model3dKey: String, andModel3dData model3dData: Data) -> URLRequest
}

extension NetworkProtocol {
    
    func buildURL(fromRequestEndPoint endPoint: NSString) -> URL? {
        guard let url = URL(string: endPoint as String) else {
            print("ERROR: Can't build URL from given end point!")
            return nil
        }
        
        print("Built url: \(url)")
        return url
    }

    func buildURLRequest(forMethod method: String, fromUrl url: URL, withBody body: AnyObject?) -> URLRequest {
        let request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60.0)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = method

        if body != nil {
            do {
                let postData = try JSONSerialization.data(withJSONObject: body!, options: JSONSerialization.WritingOptions(rawValue:0))
                let jString = NSString(data: postData, encoding: String.Encoding.utf8.rawValue)
                print("jString: <start>----\(String(describing: jString))---<end>")

                request.httpBody = postData
            }
            catch let error {
                print("Error building url request: \(error)")
            }
        }

        return request as URLRequest
    }
    
    func buildPostFormDataURLRequest(fromUrl url: URL, withBody body: AnyObject) -> URLRequest {
        let boundary = generateBoundaryString()
        let request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60.0)
        let httpBody = NSMutableData()
        
        body.enumerateKeysAndObjects { (key, value, stop) in
            httpBody.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
            httpBody.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
        }
        
        httpBody.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = httpBody as Data
        
        return request as URLRequest
    }
    
//    func buildFormDataPostURLRequest(forUrl url: URL, parameters: [String: String], fileKey: String, andImageData imageData: Data) -> URLRequest {
//        let boundary = generateBoundaryString()
//        var request = URLRequest(url: url)
//        let body = NSMutableData()
//
//        request.httpMethod = "POST"
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//        for (key, value) in parameters {
//            body.appendString("--\(boundary)\r\n")
//            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
//            body.appendString("\(value)\r\n")
//        }
//
//        let filename = "vibal-wolf-odometer-image.jpeg"
//        let mimetype = "image/jpeg"
//
//        body.appendString("--\(boundary)\r\n")
//        body.appendString("Content-Disposition: form-data; name=\"\(fileKey)\"; filename=\"\(filename)\"\r\n")
//        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
//        body.append(imageData)
//        body.appendString("\r\n")
//        body.appendString("--\(boundary)--\r\n")
//
//        request.httpBody = body as Data
//
//        return request
//    }
    
    func buildPostFormDataURLRequest(fromUrl url: URL, withParameters parameters: [String: Any], imageKey: String, andImageData imageData: Data) -> URLRequest {
        let boundary = generateBoundaryString()
        var request = URLRequest(url: url)
        let httpBody = NSMutableData()

        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        for (key, value) in parameters {
            httpBody.appendString("--\(boundary)\r\n")
            httpBody.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            httpBody.appendString("\(value)\r\n")
        }

        let imageName = "image.jpeg"
        let mimetype = "image/jpeg"

        httpBody.appendString("--\(boundary)\r\n")
        httpBody.appendString("Content-Disposition: form-data; name=\"\(imageKey)\"; filename=\"\(imageName)\"\r\n")
        httpBody.appendString("Content-Type: \(mimetype)\r\n\r\n")
        httpBody.append(imageData)
        httpBody.appendString("\r\n")
        httpBody.appendString("--\(boundary)--\r\n")

        request.httpBody = httpBody as Data

        return request
    }
    
    func buildPostFormDataURLRequest(fromUrl url: URL, withParameters parameters: [String: Any], imageKey: String, imageData: Data, model3dKey: String, andModel3dData model3dData: Data) -> URLRequest {
        let boundary = generateBoundaryString()
        var request = URLRequest(url: url)
        let httpBody = NSMutableData()
        
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        for (key, value) in parameters {
            httpBody.appendString("--\(boundary)\r\n")
            httpBody.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            httpBody.appendString("\(value)\r\n")
        }
        
        let imageName = "image.jpeg"
        let imageMimetype = "image/jpeg"
        
        httpBody.appendString("--\(boundary)\r\n")
        httpBody.appendString("Content-Disposition: form-data; name=\"\(imageKey)\"; filename=\"\(imageName)\"\r\n")
        httpBody.appendString("Content-Type: \(imageMimetype)\r\n\r\n")
        httpBody.append(imageData)
        httpBody.appendString("\r\n")
        
        let model3dName = "model3d.dae"
        let model3dMimetype = "application/octet-stream"
        
        httpBody.appendString("--\(boundary)\r\n")
        httpBody.appendString("Content-Disposition: form-data; name=\"\(model3dKey)\"; filename=\"\(model3dName)\"\r\n")
        httpBody.appendString("Content-Type: \(model3dMimetype)\r\n\r\n")
        httpBody.append(model3dData)
        httpBody.appendString("\r\n")
        httpBody.appendString("--\(boundary)--\r\n")
        
        request.httpBody = httpBody as Data
        
        return request
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
}

protocol ARFRoutes: ParserProtocol, NetworkProtocol {
    func route(_ uri: String, withBody body: AnyObject) -> URLRequest?
    func route(_ uri: String, forMethod method: String, andBody body: AnyObject?) -> URLRequest?
    func route(_ uri: String, withParameters parameters: [String: Any], imageKey: String, andImageData imageData: Data) -> URLRequest?
    func route(_ uri: String, withParameters parameters: [String: Any], imageKey: String, imageData: Data, model3dKey: String, andModel3dData model3dData: Data) -> URLRequest?
//    func route(withMethod method: String, uri: String, andQuery query: [String: AnyObject]?, body: [String: AnyObject]?) -> URLRequest?
}

extension ARFRoutes {
    
//    func route(withUri uri: String, andBody body: AnyObject) -> URLRequest? {
//        guard let url = buildURL(fromRequestEndPoint: uri as NSString) else {
//            print("ERROR: Can't build url from given end point!")
//            return nil
//        }
//
//        return buildFormDataURLRequest(forMethod: metod, fromUrl: <#T##URL#>, withBody: <#T##AnyObject#>)
//    }
    
    func route(_ uri: String, forMethod method: String, andBody body: AnyObject?) -> URLRequest? {
        guard let url = buildURL(fromRequestEndPoint: uri as NSString) else {
            print("ERROR: Can't build url from given end point!")
            return nil
        }

        return buildURLRequest(forMethod: method, fromUrl: url, withBody: body)
    }
    
    func route(_ uri: String, withBody body: AnyObject) -> URLRequest? {
        guard let url = buildURL(fromRequestEndPoint: uri as NSString) else {
            print("ERROR: Can't build url from given end point!")
            return nil
        }

        return buildPostFormDataURLRequest(fromUrl: url, withBody: body)
    }
    
    func route(_ uri: String, withParameters parameters: [String: Any], imageKey: String, andImageData imageData: Data) -> URLRequest? {
        guard let url = buildURL(fromRequestEndPoint: uri as NSString) else {
            print("ERROR: Can't build url from given end point!")
            return nil
        }

        return buildPostFormDataURLRequest(fromUrl: url, withParameters: parameters, imageKey: imageKey, andImageData: imageData)
    }
    
//    func route(withMethod method: String, uri: String, andQuery query: [String: AnyObject]?, body: [String: AnyObject]?) -> URLRequest? {
//        guard var url = buildURL(fromRequestEndPoint: uri as NSString) else {
//            print("ERROR: Can't build url from given end point!")
//            return nil
//        }
//
//        if let dictionary = query {
//            var queryVariables = [URLQueryItem]()
//
//            for (name, object) in dictionary {
//                let value = object as! String
//                let queryObject = URLQueryItem(name: name, value: value)
//                queryVariables.append(queryObject)
//            }
//
//            guard var urlComponents = URLComponents(string: url.absoluteString) else {
//                print("ERROR: Can't get url components form url!")
//                return nil
//            }
//
//            urlComponents.queryItems = queryVariables
//
//            guard let urlFromURLComponents = urlComponents.url else {
//                print("ERROR: Can't get url from url components!")
//                return nil
//            }
//
//            url = urlFromURLComponents
//        }
//
//        return buildURLRequest(forMethod: method as NSString, fromUrl: url, withBody: body as AnyObject)
//    }
    
    func route(_ uri: String, withParameters parameters: [String: Any], imageKey: String, imageData: Data, model3dKey: String, andModel3dData model3dData: Data) -> URLRequest? {
        guard let url = buildURL(fromRequestEndPoint: uri as NSString) else {
            print("ERROR: Can't build url from given end point!")
            return nil
        }
        
        return buildPostFormDataURLRequest(fromUrl: url, withParameters: parameters, imageKey: imageKey, imageData: imageData, model3dKey: model3dKey, andModel3dData: model3dData)
    }
    
}
