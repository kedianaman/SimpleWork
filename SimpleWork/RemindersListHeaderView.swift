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
        countLabel.backgroundColor = UIColor(patternImage: UIImage(named: "Number Border")!)
    }
    
    func setDimmed(dimmed: Bool, animated: Bool) {
        UIView.animateWithDuration(animated ? 0.3 : 0.0) { () -> Void in
            if let dimmedView = self.dimmedView {
                dimmedView.alpha = dimmed ? 0.75 : 0.0
            }
        }
    }
}
