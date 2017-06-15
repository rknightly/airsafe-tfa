//
//  ImageRotation.swift
//  AirSafe TFA
//
//  Created by Ryan Knightly on 6/6/17.
//  Copyright © 2017 Ryan Knightly. All rights reserved.
//

import Foundation
import UIKit

// MARK: - UIImage extensions
// Necessary for the wind sensor arrows
extension UIImage {
    public func imageRotatedByDegrees(degrees: CGFloat) -> UIImage {
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat.pi
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap!.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        bitmap!.rotate(by: degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        bitmap!.scaleBy(x: 1.0, y: -1.0)
        bitmap?.draw( cgImage!, in: CGRect(x: -size.width / 2, y: -size.height / 2,width: size.width,height: size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
