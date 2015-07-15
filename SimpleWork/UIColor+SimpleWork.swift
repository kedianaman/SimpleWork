//
//  UIColor+SimpleWork.swift
//  SimpleWork
//
//  Created by Naman Kedia on 7/13/15.
//  Copyright © 2015 Naman Kedia. All rights reserved.
//

import UIKit

extension UIColor {
    
    func distanceToColor(color : UIColor) -> Double {
        var myR: CGFloat = 0.0
        var myG: CGFloat = 0.0
        var myB: CGFloat = 0.0
        
        var theirR: CGFloat = 0.0
        var theirG: CGFloat = 0.0
        var theirB: CGFloat = 0.0

        self.getRed(&myR, green: &myG, blue: &myB, alpha: nil)
        color.getRed(&theirR, green: &theirG, blue: &theirB, alpha: nil)
        
        let redDistance = pow(Double(myR - theirR), 2.0)
        let greenDistance = pow(Double(myG - theirG), 2.0)
        let blueDistance = pow(Double(myB - theirB), 2.0)
        return sqrt(redDistance + greenDistance + blueDistance)
    }

    
    class func headerColorForCalendarColor(calendarColor : UIColor) -> UIColor {
        let myRed = UIColor(red: 240/255.0, green: 59/255.0, blue: 48/255.0, alpha: 1.0)
        let myBlue = UIColor(red: 0/255.0, green: 122/255.0, blue: 255/255.0, alpha: 1.0)
        let myGreen = UIColor(red: 76/255.0, green: 217/255.0, blue: 100/255.0, alpha: 1.0)
        let myOrange = UIColor(red: 255/255.0, green: 149/255.0, blue: 0/255.0, alpha: 1.0)
        let myPurple = UIColor(red: 88/255.0, green: 64/255.0, blue: 214/255.0, alpha: 1.0)
        let myPink = UIColor(red: 255/255.0, green: 45/255.0, blue: 85/255.0, alpha: 1.0)
        let myYellow = UIColor(red: 255/255.0, green: 204/255.0, blue: 0/255.0, alpha: 1.0)
        let myColors = [myRed, myBlue, myGreen, myOrange, myPurple, myPink, myYellow]
        
        var lowestDistance = Double(CGFloat.max)
        var matchColor = myRed
        
        for myColor in myColors {
            let distance = calendarColor.distanceToColor(myColor)
            if distance < lowestDistance {
                lowestDistance = distance
                matchColor = myColor
            }
        }
        
        // Override the red color. The myRed color above for comparison is darker so that brown matches it instead of green.
        if (matchColor == myRed) {
            matchColor = UIColor(red: 255/255.0, green: 59/255.0, blue: 48/255.0, alpha: 1.0)
        }
        
        return matchColor
    }
    
    class func cellColorForCalendarColor(calendarColor : UIColor) -> UIColor {
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        
        let color = headerColorForCalendarColor(calendarColor)
        color.getRed(&r, green: &g, blue: &b, alpha: nil)
        
        r *= 0.75
        g *= 0.75
        b *= 0.75
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}