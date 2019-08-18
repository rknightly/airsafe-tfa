//
//  BlankValueFormatter.swift
//  AirSafe
//
//  Created by Ryan Knightly on 8/13/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation
import Charts

public class BlankValueFormatter: NSObject, IAxisValueFormatter {
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return ""
    }
}
