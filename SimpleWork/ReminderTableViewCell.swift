//
//  AssignmentTableViewCell.swift
//  SimpleWork
//
//  Created by Naman Kedia on 7/13/15.
//  Copyright © 2015 Naman Kedia. All rights reserved.
//

import UIKit

protocol ReminderTableViewCellDelegate: class {
    func reminderCellDidBeginEditing(_:ReminderTableViewCell)
    func reminderCellDidFinishEditing(_:ReminderTableViewCell)
}

class ReminderCellDetailLabel : UILabel {
    
    override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var bounds = super.textRectForBounds(bounds, limitedToNumberOfLines: numberOfLines)
        if bounds.size.height != 0 {
            bounds.size.height += 2.0
        }
        return bounds
    }
    
}

class ReminderTableViewCell: UITableViewCell, UITextViewDelegate {

    weak var delegate: ReminderTableViewCellDelegate?
    
    @IBOutlet weak var titleTextView: UITextView! {
        didSet {
            titleTextView.textContainer.lineFragmentPadding = 0
            titleTextView.textContainerInset = UIEdgeInsetsZero
            titleTextView.delegate = self
        }
    }
    
    override func awakeFromNib() {
        self.tintColor = UIColor.blackColor()
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        delegate?.reminderCellDidBeginEditing(self)
        
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        delegate?.reminderCellDidFinishEditing(self)
    }
  
    @IBOutlet private weak var dueDateLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    
    @IBOutlet weak var dueDateLabelZeroHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var locationLabelZeroHeightConstraint: NSLayoutConstraint!
    
    func setDueDateText(text : String?) {
        dueDateLabel.text = text
        dueDateLabelZeroHeightConstraint.active = (text == nil)
    }
    
    func setLocationLabelText(text : String?) {
        locationLabel.text = text
        locationLabelZeroHeightConstraint.active = (text == nil)
    }
    
    @IBAction func checkBoxTapped(sender: UIButton) {
        if sender.imageForState(.Normal) == nil {
            sender.setImage(UIImage(named: "Checkmark.png"), forState: .Normal)
        } else {
            sender.setImage(nil, forState: .Normal)
            
        }
    }
}
