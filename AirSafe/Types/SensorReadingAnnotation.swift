//
//  SensorReadingAnnotation.swift
//  AirSafe
//
//  Created by Ryan Knightly on 8/9/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation
import MapKit
import Charts
import SwiftyJSON

class SensorReadingAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var sensorReading: SensorReading!
    var isDroneReading = false
    
    init(sensorReading: SensorReading) {
        self.coordinate = sensorReading.location
        self.title = sensorReading.sensorName
        self.sensorReading = sensorReading
    }
    
    func getColorName(thresholds: Thresholds?) -> String{
        if thresholds != nil {
            return thresholds!.getStatus(concentration: sensorReading.concentration).colorName
        } else {
            return "light gray"
        }
    }
    
    func getColor(thresholds: Thresholds?) -> UIColor{
        return UIColor(name: getColorName(thresholds: thresholds))!
    }
    
    /// Create a chart to display the recorded data of a sensor
    ///
    /// - Parameters:
    func getChart(pollutant: Pollutant, timeResolution: String) -> LineChartView {
        let chartView = LineChartView(frame: CGRect(x: 0, y: 0, width: 50, height: 25))
        // Set a range of 0 to 4 because the reading usually hovers between 2 and 3
        chartView.chartDescription?.enabled = false
        
        chartView.dragEnabled = false
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false
        chartView.highlightPerTapEnabled = true
        chartView.highlightPerDragEnabled = true
        
        chartView.backgroundColor = .white
        chartView.legend.enabled = false
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 12, weight: .light)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = true
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = 3600
        xAxis.valueFormatter = BlankValueFormatter()
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelPosition = .outsideChart
        leftAxis.labelFont = .systemFont(ofSize: 12, weight: .light)
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = true
//        leftAxis.axisMinimum = 0
//        leftAxis.axisMaximum = 2
//        leftAxis.granularity = 0.5
        leftAxis.valueFormatter = ConcentrationValueFormatter()
        
        chartView.rightAxis.enabled = false
        chartView.legend.form = .line
        
        // Load data from server
        var urlComponents = URLComponents(string: Config.HISTORICAL_DATA_WEB_SERVICE)!
        urlComponents.queryItems = [
            URLQueryItem(name: "pollutant", value: pollutant.abbreviation),
            URLQueryItem(name: "sensor", value: sensorReading.sensorName),
            URLQueryItem(name: "time_resolution", value: Pollutant.timeResolutionAbbreviations[timeResolution])
        ]
        URLSession.shared.dataTask(with: urlComponents.url!) { (result) in
            switch result {
            case .success( _, let data):
                // Handle Data and Response
                let json = JSON(data)
                var values = [ChartDataEntry]()
                for readingData in json.arrayValue {
                    values.append(ChartDataEntry(x: readingData["time"].doubleValue, y: readingData["concentration"].doubleValue))
                }
                values.reverse()
                
                xAxis.valueFormatter = DateValueFormatter()

                let gasDataSet = LineChartDataSet(entries: values, label: "DataSet 1")
                gasDataSet.axisDependency = .left
                gasDataSet.setColor(UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
                gasDataSet.lineWidth = 1.5
                gasDataSet.drawCirclesEnabled = false
                gasDataSet.drawValuesEnabled = false
                gasDataSet.fillAlpha = 0.26
                gasDataSet.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
                gasDataSet.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
                gasDataSet.drawCircleHoleEnabled = false
                gasDataSet.label = "Pollutant Concentration"
                
                let data = LineChartData(dataSet: gasDataSet)
                data.setValueTextColor(.white)
                data.setValueFont(.systemFont(ofSize: 9, weight: .light))
                DispatchQueue.main.async {
                    chartView.data = data
                }
                break
            case .failure(let error):
                // Handle Error
                print(error)
                break
            }
        }.resume()
        return chartView
    }
    
    func getTextView(pollutant: Pollutant) -> UITextView {
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 50, height: 25))
        textView.font = UIFont(name: "Avenir Next", size: 15)
        textView.text = [
            "Drone Sensor Reading\n",
            "Time: " + sensorReading.getDateString(),
            "Pollutant: " + pollutant.name,
            "Concentration: " + String(format: "%.2f", sensorReading.concentration)
        ].joined(separator: "\n")
        return textView
    }
}
