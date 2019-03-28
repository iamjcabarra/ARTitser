//
//  ARFChartFormatter.swift
//  ARFollow
//
//  Created by Julius Abarra on 14/03/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import Charts

class ARFChartFormatter: NSObject, IAxisValueFormatter {
    var percentages = [String]()
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return self.percentages[Int(value)]
    }

    func setValues(_ values: [String]) {
        self.percentages = values
    }
}
