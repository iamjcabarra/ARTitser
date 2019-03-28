//
//  ARFDataParserHelper.swift
//  ARFollow
//
//  Created by Julius Abarra on 12/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import Foundation

protocol ParserProtocol {
    func json(fromData data: Data) -> Any?
    var dateFormatter: DateFormatter { get set }
    var userDefaults: UserDefaults { get set }
}

extension ParserProtocol {
    func json(fromData data: Data) -> Any? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        }
        catch let error {
            print("Error parsing response data: \(error)")
        }
        
        return nil
    }
    
    func string(_ value: Any?) -> String {
        guard let v = value else { return "" }
        let newValue = "\(v)"
        if (newValue == "null") || (newValue == "<null>") || (newValue == "(null)") { return "" }
        return newValue
    }
    
    func doubleString(_ string: String) -> Double {
        guard let d = Double(string) else { return 0.0 }
        return d
    }
    
    func intString(_ string: String) -> Int64 {
        guard let i = Int64(string) else { return 0 }
        return i
    }
    
    func userDefaultsSave(object: Any, forKey key: String) {
        self.userDefaults.set(object, forKey: key)
        self.userDefaults.synchronize()
    }
    
    func userDefaultsFetchObject(forKey key: String) -> Any {
        let object = self.userDefaults.object(forKey: key)
        if object == nil { return "" as Any }
        return object as Any
    }
    
    func userDefaultsRemoveObject(forKey key: String) {
        self.userDefaults.removeObject(forKey: key)
    }
    
    func date(fromString string: String, format: String) -> Date {
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        
        guard let date = dateFormatter.date(from: string) else {
            print("ERROR: Can't create date!")
            return Date()
        }
        
        return date
    }
    
    func string(fromDate date: Date, format: String) -> String {
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        return dateFormatter.string(from: date)
    }
    
    func addDays(_ days: Int, toDate date: Date) -> Date {
        guard let date = (Calendar.current as NSCalendar).date(byAdding: .day, value: days, to: date, options: []) else {
            return Date()
        }
        
        return date
    }
}
