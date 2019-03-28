//
//  ARFBarChart.swift
//  ARFollow
//
//  Created by Julius Abarra on 14/03/2018.
//  Copyright © 2018 exZeptional. All rights reserved.
//

import UIKit
import Charts

class ARFBarChart: UIView {

    /// Properties
    let barChartView = BarChartView()
    var dataEntry: [BarChartDataEntry] = []
    
    /// Chart data
    var percentages = [String]()
    var ratePerGame = [String]()
    var gameNames = [String]()
    
    var delegate: GetChartData! {
        didSet {
            populateData()
            barChartSetup()
        }
    }
    
    /// Populate bar chart's data
    func populateData() {
        percentages = delegate.percentages
        ratePerGame = delegate.ratePerGame
        gameNames = delegate.gameNames
    }
    
    /// Configures bar chart
    func barChartSetup() {
        self.backgroundColor = UIColor.white
        self.addSubview(barChartView)
        barChartView.translatesAutoresizingMaskIntoConstraints = false
        barChartView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        barChartView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        barChartView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        barChartView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        barChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .easeInBounce)
        setBarChart(with: percentages, values: ratePerGame, names: gameNames)
    }
    
    /// Renders bar chart
    func setBarChart(with dataPoints: [String], values: [String], names: [String]) {
        barChartView.noDataTextColor = UIColor.black
        barChartView.noDataText = "No data for the chart."
        barChartView.backgroundColor = UIColor(hex: "95D5FF")
        
        for i in 0..<values.count {
            let dataPoint = BarChartDataEntry(x: Double(i), y: Double(values[i])!)
            dataEntry.append(dataPoint)
        }
        
        let chartDataSet = BarChartDataSet(values: dataEntry, label: "% Success")
        let chartData = BarChartData()
        chartData.addDataSet(chartDataSet)
        chartData.setDrawValues(false)
        chartDataSet.colors = [UIColor(hex: "1D65A6")]
        
        let formatter: ARFChartFormatter = ARFChartFormatter()
        formatter.setValues(dataPoints)
        barChartView.xAxis.labelCount = values.count
        barChartView.xAxis.labelPosition = .bottom
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: names)
        barChartView.xAxis.granularity = 1
        barChartView.chartDescription?.enabled = false
        barChartView.legend.enabled = true
        barChartView.rightAxis.enabled = false
        barChartView.leftAxis.drawGridLinesEnabled = true
        barChartView.leftAxis.drawLabelsEnabled = true
        barChartView.data = chartData
    }

}
