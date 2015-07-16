//
//  RemindersListHeaderView.swift
//  SimpleWork
//
//  Created by Naman Kedia on 7/14/15.
//  Copyright © 2015 Naman Kedia. All rights reserved.
//

import UIKit

class RemindersCountLabel : UILabel {
    override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var bounds = super.textRectForBounds(bounds, limitedToNumberOfLines: numberOfLines)
        bounds.size.width += 24.0
        return bounds
    }
}

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
        
        countLabel.backgroundColor = UIColor(white: 0.0, alpha: 0.1)
        countLabel.layer.cornerRadius = countLabel.frame.size.height/2.0
        countLabel.layer.masksToBounds = true
        
//        countLabel.backgroundColor = UIColor(patternImage: UIImage(named: "Number Border")!)
    }
    
    func setDimmed(dimmed: Bool, animated: Bool) {
        UIView.animateWithDuration(animated ? 0.3 : 0.0) { () -> Void in
            if let dimmedView = self.dimmedView {
                dimmedView.alpha = dimmed ? 0.75 : 0.0
            }
        }
    }
}
