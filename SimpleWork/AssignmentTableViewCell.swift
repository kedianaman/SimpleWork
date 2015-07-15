//
//  AssignmentTableViewCell.swift
//  SimpleWork
//
//  Created by Naman Kedia on 7/13/15.
//  Copyright © 2015 Naman Kedia. All rights reserved.
//

import UIKit

class AssignmentTableViewCell: UITableViewCell, UITextFieldDelegate {

    
    @IBOutlet weak var assignmentTitleTextField: UITextField! {
        didSet {
            assignmentTitleTextField.delegate = self
            assignmentTitleTextField.keyboardAppearance = UIKeyboardAppearance.Dark
        }
    }
    @IBOutlet weak var dateLabel: UILabel!
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    

    @IBAction func checkBoxTapped(sender: UIButton) {
        if sender.imageForState(.Normal) == nil {
            sender.setImage(UIImage(named: "Checkmark.png"), forState: .Normal)
        } else {
            sender.setImage(nil, forState: .Normal)
            
        }
    }
}
