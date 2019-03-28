//
//  ARFExtensions.swift
//  ARFollow
//
//  Created by Julius Abarra on 12/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import Foundation
import UIKit

// UIColor

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}

// Double

extension Double {
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// NSMutableData

extension NSMutableData {
    func appendString(_ string: String) {
        if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true) {
            append(data)
        }
    }
}

// UIImage

extension UIImage {
    var pngRepresentationData: Data? {
        return UIImagePNGRepresentation(self)
    }
    
    var jpegRepresentationData: Data? {
        return UIImageJPEGRepresentation(self, 1)
    }
}

// Date

extension Date {
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}

// UIView

extension UIView {
    func addShadow(offset: CGSize, color: UIColor, radius: CGFloat, opacity: Float) {
        let layer = self.layer
        layer.masksToBounds = false
        layer.shadowOffset = offset
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        
        let backgroundCGColor = self.backgroundColor?.cgColor
        self.backgroundColor = nil
        layer.backgroundColor =  backgroundCGColor
    }
}

// UITextField

extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    
    func setRightPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

// UIButton

extension UIButton {
    
    func flash() {
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.duration = 0.2
        flash.fromValue = 1
        flash.toValue = 0.1
        flash.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        flash.autoreverses = true
        flash.repeatCount = 5
        
        layer.add(flash, forKey: nil)
    }

    func shake() {
        let shake = CABasicAnimation(keyPath: "position")
        shake.duration = 0.05
        shake.repeatCount = 5
        shake.autoreverses = true
        
        let fPoint = CGPoint(x: center.x - 5, y: center.y)
        let fValue = NSValue(cgPoint: fPoint)
        let tPoint = CGPoint(x: center.x + 5, y: center.y)
        let tValue = NSValue(cgPoint: tPoint)
        
        shake.fromValue = fValue
        shake.toValue = tValue
        
        layer.add(shake, forKey: "position")
    }
}
