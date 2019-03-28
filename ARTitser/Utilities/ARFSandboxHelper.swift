//
//  ARFSandboxHelper.swift
//  ARFollow
//
//  Created by Julius Abarra on 27/01/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import Foundation

class ARFSandboxHelper: NSObject {
    
    fileprivate let fileManager = FileManager.default
    
    func makeSubdirectoryInDocumentsDirectory(withName name: String) -> String {
        let directoryPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectoryPath = directoryPaths[0]
        let subdirectoryName = name.hasPrefix("/") ? name : "/\(name)"
        let subdirectoryPath = (documentsDirectoryPath as NSString).appendingPathComponent(subdirectoryName)
        
        if (!self.fileManager.fileExists(atPath: subdirectoryPath)) {
            do {
                try self.fileManager.createDirectory(atPath: subdirectoryPath, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError {
                print(error.localizedDescription);
            }
        }
        
        return subdirectoryPath
    }
    
    func retrieveContentsOfDirectory(atPath path: String) -> Array<String> {
        var contents = [String]()
        
        do {
            contents = try self.fileManager.contentsOfDirectory(atPath: path)
        }
        catch let error as NSError {
            print(error.localizedDescription);
        }
        
        return contents
    }
    
    func retrieveFilesInDirectory(atPath path: String) -> Array<String> {
        let contents = self.retrieveContentsOfDirectory(atPath: path)
        var files = [String]()
        
        for item in contents {
            let itemPath = (path as NSString).appendingPathComponent(item)
            let isDirectory = self.isItemAtPathADirectory(itemPath)
            
            if (!isDirectory) {
                files.append(itemPath)
            }
        }
        
        return files
    }
    
    func retrieveAttributesOfFile(atPath path: String) -> [FileAttributeKey : Any] {
        var attributes = [FileAttributeKey : Any]()
        
        do {
            attributes = try self.fileManager.attributesOfItem(atPath: path)
        }
        catch let error as NSError {
            print(error.localizedDescription);
        }
        
        return attributes
    }
    
    func isItemAtPathADirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = ObjCBool(false)
        
        if self.fileManager.fileExists(atPath: path, isDirectory:&isDirectory) {
            return isDirectory.boolValue
        }
        
        return isDirectory.boolValue
    }
    
    func formattedStringSize(_ size: Int64) -> String {
        var convertedSize = Double(size) / 8
        var factorMultiplier = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB"]
        
        while (convertedSize > 1024) {
            convertedSize /= 1024
            factorMultiplier += 1
        }
        
        let convertedSizeString = String(format: "%.2f", convertedSize)
        return "\(convertedSizeString) \(tokens[factorMultiplier])"
    }
    
}
