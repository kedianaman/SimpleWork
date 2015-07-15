//
//  RemindersListHeaderView.swift
//  SimpleWork
//
//  Created by Naman Kedia on 7/14/15.
//  Copyright © 2015 Naman Kedia. All rights reserved.
//

import UIKit

class RemindersListHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var subtitleTextField: UITextField!
    @IBOutlet weak var countLabel: UILabel!
    var dimmedView: UIView?
    
    override func awakeFromNib() {
        backgroundView = UIView(frame: self.bounds)
        dimmedView = UIView(frame: self.bounds)
        if let dimmedView = dimmedView {
            self.addSubview(dimmedView)
            dimmedView.backgroundColor = UIColor.blackColor()
            dimmedView.alpha = 0.0
        }
    }
    
    func setDimmed(dimmed: Bool, animated: Bool) {
        var alphaToSet:CGFloat = 0.0
        if dimmed == true {
            alphaToSet = 0.75
        }
        if let dimmedView = dimmedView {
            if animated == true {
                UIView.animateWithDuration(0.4,
                    delay: 0,
                    options: UIViewAnimationOptions.CurveLinear,
                    animations: { dimmedView.alpha = alphaToSet },
                    completion: nil)
            }
            else {
                dimmedView.alpha = alphaToSet
            }
        }
       
        
    }
}
