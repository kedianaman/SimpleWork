//
//  MainTableViewController.swift
//  SimpleWork
//
//  Created by Naman Kedia on 7/12/15.
//  Copyright © 2015 Naman Kedia. All rights reserved.
//

import UIKit
import EventKit

class MainTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RemindersListHeaderViewDelegate, ReminderTableViewCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let eventStore = EKEventStore()
    var calendars = [EKCalendar]()
    var remindersInCalendar = [String : [EKReminder]]()  // calendarIdentifier -> EKReminder

    var selectedSectionIndex: Int?
    var addingNewReminder: Bool?
    var editingTextAtIndexPath: NSIndexPath?
    
    var visibleHeaders = [Int: RemindersListHeaderView]()   // section -> headerView

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 49
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 102
        
        tableView.registerNib(UINib(nibName: "RemindersListHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "HeaderView")
        
        tableView.separatorColor = UIColor(white: 0.0, alpha: 0.25)
        // TODO: Remove 56 magic number
        tableView.separatorInset = UIEdgeInsetsMake(0, 56, 0, 0)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidShow:"), name: UIKeyboardDidShowNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        checkReminderAuthorizationStatus()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contentInset = defaultContentInset()
    }
    
    // MARK: - UIGestures
    
    @IBAction func headerViewTapped(sender: UITapGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.Recognized) {
            var indexPathsToInsert = [NSIndexPath]()
            var indexPathsToDelete = [NSIndexPath]()
       
            if selectedSectionIndex == nil {
                // Show the newly selected section
                selectedSectionIndex = sender.view!.tag
                if let headerView = tableView.headerViewForSection(selectedSectionIndex!) as? RemindersListHeaderView {
                    headerView.addButton.enabled = true
                    headerView.addButton.alpha = 1.0
                    headerView.countLabel.alpha = 0.0
                }
                
                for (index, header) in visibleHeaders {
                    if index != selectedSectionIndex {
                        header.setDimmed(true, animated: true)
                    }
                }
                
                let remindersCount = tableView(tableView, numberOfRowsInSection: selectedSectionIndex!)
                if remindersCount > 0 {
                    for row in 0...remindersCount - 1  {
                        indexPathsToInsert.append(NSIndexPath(forRow: row, inSection: selectedSectionIndex!))
                    }
                }
               
                
            } else {
                // Collapse the currently selected section
                if let headerView = tableView.headerViewForSection(selectedSectionIndex!) as? RemindersListHeaderView {
                    headerView.addButton.enabled = false
                    headerView.addButton.alpha = 0.0
                    headerView.countLabel.alpha = 1.0
                }
                for (_, header) in visibleHeaders {
                    header.setDimmed(false, animated: true)
                }
                
                let remindersCount = tableView(tableView, numberOfRowsInSection: selectedSectionIndex!)
                if remindersCount > 0 {
                    for row in 0...remindersCount - 1  {
                        indexPathsToDelete.append(NSIndexPath(forRow: row, inSection: selectedSectionIndex!))
                    }

                }
                
                selectedSectionIndex = nil

            }
            
            tableView.beginUpdates()
            if (indexPathsToDelete.count > 0) {
                tableView.deleteRowsAtIndexPaths(indexPathsToDelete, withRowAnimation: UITableViewRowAnimation.Top)
            }
            if (indexPathsToInsert.count > 0) {
                tableView.insertRowsAtIndexPaths(indexPathsToInsert, withRowAnimation: UITableViewRowAnimation.Top)
            }
            tableView.endUpdates()
            
            if let selectedSectionIndex = selectedSectionIndex {
                let rect = self.tableView.rectForSection(selectedSectionIndex)
                if rect.size.height > tableViewVisibleBounds().size.height {
                    self.tableView.setContentOffset(CGPointMake(0, self.tableView.rectForHeaderInSection(self.selectedSectionIndex!).origin.y), animated: true)
                }
                else {
                    self.tableView.scrollRectToVisible(rect, animated: true)
                }
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    var contentInset = self.defaultContentInset()
                    contentInset.bottom += rect.size.height
                    self.tableView.contentInset = contentInset
                    }, completion: { (completed) -> Void in
                        self.tableView.contentInset = self.defaultContentInset()
                })
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func defaultContentInset() -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, view.bounds.size.height + topLayoutGuide.length, 0)
    }
    
    private func tableViewVisibleBounds() -> CGRect {
        var frame = tableView.frame
        frame.size.height = view.bounds.size.height - topLayoutGuide.length
        return frame
    }
    
    private func tableViewContentSize() -> CGSize {
        var contentSize: CGFloat = 0.0
        for section in 0..<tableView.numberOfSections {
            var sectionHeight = tableView.rectForHeaderInSection(section).height
            for row in 0..<tableView.numberOfRowsInSection(section) {
                sectionHeight += tableView.rectForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section)).height
            }
            contentSize += sectionHeight
        }
        return CGSizeMake(tableView.bounds.size.width, contentSize)
    }
    
    // MARK: - Getting Calendars / Reminders
    
    func checkReminderAuthorizationStatus() {
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Reminder)
        switch status {
        case EKAuthorizationStatus.NotDetermined:
            requestAccessToReminders()
        case EKAuthorizationStatus.Authorized:
            loadCalendars()
            loadReminders()
        case EKAuthorizationStatus.Restricted, EKAuthorizationStatus.Denied:
            print("Access denied")
        }
        
    }
    
    func requestAccessToReminders() {
        eventStore.requestAccessToEntityType(EKEntityType.Reminder) { [unowned self] (granted, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.loadCalendars()
                self.loadReminders()
            })
        }
    }
    
    func loadCalendars() {
        calendars = eventStore.calendarsForEntityType(EKEntityType.Reminder)
        calendars.sortInPlace { (calendar1, calendar2) -> Bool in
            return calendar1.title < calendar2.title
        }
        tableView.reloadData()
    }
    
    func loadReminders() {
        remindersInCalendar.removeAll()
        
        for calendar in calendars {
            let predicate = eventStore.predicateForIncompleteRemindersWithDueDateStarting(nil, ending: nil, calendars: [calendar])
            eventStore.fetchRemindersMatchingPredicate(predicate) { [unowned self] (remindersArray) -> Void in
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    self.remindersInCalendar[calendar.calendarIdentifier] = remindersArray
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return calendars.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let selectedSectionIndex = selectedSectionIndex {
            if section == selectedSectionIndex {
                let calendar = calendars[section]
                let reminders = remindersInCalendar[calendar.calendarIdentifier]
                if reminders!.count > 0 {
                    if addingNewReminder == true {
                        return reminders!.count + 1
                    } else {
                        return reminders!.count
                    }
                } else {
                    return 1
                }
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let calendar = calendars[indexPath.section]
        let remindersForCalendar = remindersInCalendar[calendar.calendarIdentifier]
        var reminder: EKReminder?
        if let remindersForCalendar = remindersForCalendar {
            if indexPath.row < remindersForCalendar.count {
                reminder = remindersForCalendar[indexPath.row]
            }
        }
        if reminder != nil || addingNewReminder == true {
            if let cell = tableView.dequeueReusableCellWithIdentifier("ReminderCell", forIndexPath: indexPath) as? ReminderTableViewCell {
                cell.delegate = self
                cell.setDueDateText(nil)
                cell.setLocationLabelText(nil)
                
                
                cell.titleTextView.text = reminder?.title
                let dateComponents = reminder?.dueDateComponents
                if let dateComponents = dateComponents {
                    let formatter = NSDateFormatter()
                    formatter.dateStyle = NSDateFormatterStyle.MediumStyle
                    formatter.timeStyle = NSDateFormatterStyle.ShortStyle
                    formatter.doesRelativeDateFormatting = true
                    
                    let date = NSCalendar.currentCalendar().dateFromComponents(dateComponents)
                    if let date = date {
                        cell.setDueDateText(formatter.stringFromDate(date))
                    }
                }
                
                cell.backgroundColor = UIColor.cellColorForCalendarColor(UIColor(CGColor: calendar.CGColor))
                
                return cell

            }
        
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("Placeholder Cell", forIndexPath: indexPath)
            cell.backgroundColor = UIColor.cellColorForCalendarColor(UIColor(CGColor: calendar.CGColor))
            return cell
        }
        return tableView.cellForRowAtIndexPath(indexPath)!
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let calendar = calendars[section]
        
        var headerView = visibleHeaders[section]
        if headerView == nil {
            headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier("HeaderView") as? RemindersListHeaderView
            headerView?.delegate = self 
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "headerViewTapped:")
            headerView!.addGestureRecognizer(tapGestureRecognizer)
        }

        if let headerView = headerView {
            headerView.titleTextField.text = calendar.title
            headerView.subtitleTextField.text = calendar.source.title
            let numReminders = remindersInCalendar[calendar.calendarIdentifier]?.count
            if let numReminders = numReminders {
                headerView.countLabel.text = String(numReminders)
            }
                        
            headerView.backgroundView!.backgroundColor = UIColor.headerColorForCalendarColor(UIColor(CGColor: calendar.CGColor))
            headerView.layer.shadowColor = UIColor.blackColor().CGColor
            headerView.layer.shadowOffset = CGSizeMake(0, -1)
            headerView.layer.shadowOpacity = 0.2
            headerView.layer.shadowPath = UIBezierPath(rect: headerView.bounds).CGPath
            headerView.layer.shadowRadius = 4
            headerView.layer.zPosition = CGFloat(section)
            headerView.clipsToBounds = false
            headerView.layer.masksToBounds = false
            
            headerView.tag = section
            
            let dimmed = (selectedSectionIndex != nil) ? selectedSectionIndex! != section : false
            headerView.setDimmed(dimmed, animated: false)
        }

        return headerView
    }
    
    // MARK: - Table View Delegate
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        visibleHeaders[section] = view as? RemindersListHeaderView
    }
    
    func tableView(tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        visibleHeaders.removeValueForKey(section)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let calendar = calendars[indexPath.section]
            let reminders = remindersInCalendar[calendar.calendarIdentifier]
            if var reminders = reminders {
                do {
                    try eventStore.removeReminder(reminders[indexPath.row], commit: true)
                    reminders.removeAtIndex(indexPath.row)
                    remindersInCalendar[calendar.calendarIdentifier] = reminders
                    if let headerView = tableView.headerViewForSection(selectedSectionIndex!) as? RemindersListHeaderView {
                        headerView.countLabel.text = String(remindersInCalendar[calendar.calendarIdentifier]!.count)
                    }
                } catch _ {
                    print("didn't work")
                }
                
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            
        }
    }
    
    // MARK: - RemindersListHeaderView Delegate 
    func headerViewDidSelectAddReminder(_ : RemindersListHeaderView) {
        addingNewReminder = true
        let remindersCount = tableView(tableView, numberOfRowsInSection: selectedSectionIndex!)
        let indexPathForRow = NSIndexPath(forRow: remindersCount - 1, inSection: selectedSectionIndex!)
        let calendar = calendars[selectedSectionIndex!]
        let reminders = remindersInCalendar[calendar.calendarIdentifier]
        
        tableView.beginUpdates()
        if reminders?.count == 0 {
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: selectedSectionIndex!)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        tableView.insertRowsAtIndexPaths([indexPathForRow], withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.endUpdates()
        
        for (_, headers) in visibleHeaders {
            for gesture in headers.gestureRecognizers! {
                gesture.enabled = false
            }
        }

        if let remindersCell = tableView.cellForRowAtIndexPath(indexPathForRow) as? ReminderTableViewCell {
            editingTextAtIndexPath = indexPathForRow
            remindersCell.titleTextView.becomeFirstResponder()
        }
    }
    
    func headerViewDidFinishAddingReminder(headerView: RemindersListHeaderView) {
        addingNewReminder = false
        tableView.scrollEnabled = true
        for (_, headers) in visibleHeaders {
            for gesture in headers.gestureRecognizers! {
                gesture.enabled = true
            }
        }
        let calendar = calendars[selectedSectionIndex!]
        let reminders = remindersInCalendar[calendar.calendarIdentifier]

        let remindersCount = reminders?.count
        let indexPathForRow = NSIndexPath(forRow: remindersCount!, inSection: selectedSectionIndex!)
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = calendar
        
        if let remindersCell = tableView.cellForRowAtIndexPath(indexPathForRow) as? ReminderTableViewCell {
            remindersCell.titleTextView.resignFirstResponder()
            if let reminderTitle = remindersCell.titleTextView.text {
                reminder.title = reminderTitle
            }
        }
        if reminder.title != "" {
            do {
                try eventStore.saveReminder(reminder, commit: true)
                remindersInCalendar[calendar.calendarIdentifier]?.append(reminder)
                headerView.countLabel.text = String(remindersInCalendar[calendar.calendarIdentifier]!.count)
            } catch _ {
                print("didn't work")
            }
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                let maxContentOffset = self.tableViewContentSize().height - self.tableViewVisibleBounds().height
                if self.tableView.contentOffset.y > maxContentOffset {
                    self.tableView.contentOffset = CGPointMake(0, maxContentOffset)
                }
                else {
                    // Show entire section if possible.
                    // Otherwise, scroll the section with UITableViewScrollPosition.Bottom
                    let sectionRect = self.tableView.rectForSection(self.selectedSectionIndex!)
                    if sectionRect.height < self.tableViewVisibleBounds().height {
                        self.tableView.scrollRectToVisible(sectionRect, animated: false)
                    }
                    else {
                        self.tableView.scrollToRowAtIndexPath(indexPathForRow, atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
                    }
                }
                }) { (completed) -> Void in
                    self.tableView.contentInset = self.defaultContentInset()
            }
        } else {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                let maxContentOffset = self.tableViewContentSize().height - self.tableViewVisibleBounds().height - self.tableView.rectForRowAtIndexPath(indexPathForRow).height
                if self.tableView.contentOffset.y > maxContentOffset {
                    self.tableView.contentOffset = CGPointMake(0, maxContentOffset)
                }
                }) { (completed) -> Void in
                    self.tableView.contentInset = self.defaultContentInset()
            }
            tableView.deleteRowsAtIndexPaths([indexPathForRow], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
//        print(scrollView.contentOffset)
    }
    
    // MARK: - ReminderTableViewCell Delegate
    
    func reminderCellDidBeginEditing(reminderCell: ReminderTableViewCell) {
        print("began editing")
    }
    
    func reminderCellDidFinishEditing(reminderCell: ReminderTableViewCell) {
        print("finished editing")
        editingTextAtIndexPath = nil
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo as! [NSString : NSObject]
        let frame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let animationDuration = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animationOptions = UIViewAnimationOptions(rawValue:UInt((info[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
        
        var inset = defaultContentInset()
        inset.bottom += frame.height
        tableView.contentInset = inset
        
        if let editingTextAtIndexPath = editingTextAtIndexPath {
            UIView.animateWithDuration(animationDuration, delay: 0.0, options: animationOptions, animations: { () -> Void in
                self.tableView.scrollToRowAtIndexPath(editingTextAtIndexPath, atScrollPosition: UITableViewScrollPosition.None, animated: false)
                }, completion: nil)
        }
    }

    func keyboardDidShow(notification: NSNotification) {
//        if let selectedSectionIndex = selectedSectionIndex {
//            
//        }
    }
    
    

}
