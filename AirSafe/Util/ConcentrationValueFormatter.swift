//
//  ConcentrationValueFormatter.swift
//  AirSafe
//
//  Created by Ryan Knightly on 7/28/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation
import Charts

public class ConcentrationValueFormatter: NSObject, IAxisValueFormatter {
    
    override init() {
        super.init()
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(format: "%.2f", value)
    }
}
