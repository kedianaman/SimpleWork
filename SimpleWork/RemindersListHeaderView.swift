//
//  RemindersListHeaderView.swift
//  SimpleWork
//
//  Created by Naman Kedia on 7/14/15.
//  Copyright © 2015 Naman Kedia. All rights reserved.
//

import UIKit

class RemindersListHeaderView: UIView {
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 600, height: 101))
        NSBundle.mainBundle().loadNibNamed("RemindersListHeaderView", owner: self, options: nil)
        self.addSubview(view)
        view.backgroundColor = UIColor.clearColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var subtitleTextField: UITextField!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet var view: UIView!
    
}
