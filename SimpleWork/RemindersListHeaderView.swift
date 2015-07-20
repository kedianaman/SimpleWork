//
//  RemindersListHeaderView.swift
//  SimpleWork
//
//  Created by Naman Kedia on 7/14/15.
//  Copyright © 2015 Naman Kedia. All rights reserved.
//

import UIKit

protocol RemindersListHeaderViewDelegate: class {
    func headerViewDidSelectAddReminder(_ : RemindersListHeaderView)
}
class RemindersCountLabel : UILabel {
    override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var bounds = super.textRectForBounds(bounds, limitedToNumberOfLines: numberOfLines)
        bounds.size.width += 24.0
        return bounds
    }
}

class RemindersListHeaderView: UITableViewHeaderFooterView {
    
    weak var delegate: RemindersListHeaderViewDelegate?
    
    @IBAction func addReminder() {
        delegate?.headerViewDidSelectAddReminder(self)
        
    }
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var subtitleTextField: UITextField!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var dimmedView: UIView!
    
    override func awakeFromNib() {
        backgroundView = UIView(frame: self.bounds)
        
        countLabel.backgroundColor = UIColor(white: 0.0, alpha: 0.1)
        countLabel.layer.cornerRadius = countLabel.frame.size.height/2.0
        countLabel.layer.masksToBounds = true
    }
    
    func setDimmed(dimmed: Bool, animated: Bool) {
        UIView.animateWithDuration(animated ? 0.3 : 0.0) { () -> Void in
            if let dimmedView = self.dimmedView {
                dimmedView.alpha = dimmed ? 0.75 : 0.0
            }
        }
    }
}
