//
//  MainTableViewController.swift
//  SimpleWork
//
//  Created by Naman Kedia on 7/12/15.
//  Copyright © 2015 Naman Kedia. All rights reserved.
//

import UIKit
import EventKit

class MainTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    let eventStore = EKEventStore()
    var calendars = [EKCalendar]()
    var remindersInCalendar = [String : [EKReminder]]()  // calendarIdentifier -> EKReminder
    var selectedSectionIndex: Int?
    
    var visibleHeaders = [Int: RemindersListHeaderView]()   // section -> headerView

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.registerNib(UINib(nibName: "RemindersListHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "HeaderView")
        
        tableView.separatorColor = UIColor(white: 0.0, alpha: 0.25)
        // TODO: Remove 56 magic number
        tableView.separatorInset = UIEdgeInsetsMake(0, 56, 0, 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        checkReminderAuthorizationStatus()
    }
    
    // MARK: - UIGestures

    
    @IBAction func headerViewTapped(sender: UITapGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.Recognized) {
            print("selected Index before starting : \(selectedSectionIndex)")
            
            var indexPathsToInsert = [NSIndexPath]()
            var indexPathsToDelete = [NSIndexPath]()
       
            if selectedSectionIndex == nil {
                // Show the newly selected section
                selectedSectionIndex = sender.view!.tag
                
                for (index, header) in visibleHeaders {
                    if index != selectedSectionIndex {
                        header.setDimmed(true, animated: true)
                    }
                }
                
                let calendar = calendars[selectedSectionIndex!]
                let reminders = remindersInCalendar[calendar.calendarIdentifier]!
                if reminders.count > 0 {
                    for row in 0...reminders.count - 1  {
                        indexPathsToInsert.append(NSIndexPath(forRow: row, inSection: selectedSectionIndex!))
                    }
                }
               
                
            } else {
                // Collapse the currently selected section
                for (_, header) in visibleHeaders {
                    header.setDimmed(false, animated: true)
                }
                let calendar = calendars[selectedSectionIndex!]
                let reminders = remindersInCalendar[calendar.calendarIdentifier]!
                if reminders.count > 0 {
                    for row in 0...reminders.count - 1  {
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
            
            UIView.animateWithDuration(0.3) { () -> Void in
                if self.selectedSectionIndex == nil {
                    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
                } else {
                    self.tableView.contentInset = UIEdgeInsetsMake(-self.tableView.rectForHeaderInSection(self.selectedSectionIndex!).origin.y, 0, 0, 0)
                    self.tableView.contentOffset = CGPointMake(0, -self.tableView.contentInset.top)
                }
            }
        }
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
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return calendars.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let selectedSectionIndex = selectedSectionIndex {
            if section == selectedSectionIndex {
                let calendar = calendars[section]
                let reminders = remindersInCalendar[calendar.calendarIdentifier]
                return reminders!.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("ReminderCell", forIndexPath: indexPath) as? ReminderTableViewCell {
            
            cell.setDueDateText(nil)
            cell.setLocationLabelText(nil)

            
            let calendar = calendars[indexPath.section]
            let remindersForCalendar = remindersInCalendar[calendar.calendarIdentifier]
            let reminder = remindersForCalendar?[indexPath.row]
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
        return tableView.cellForRowAtIndexPath(indexPath)!
    }
    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return CGFloat(66)
//    }

    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(101)
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let calendar = calendars[section]
        
        var headerView = visibleHeaders[section]
        if headerView == nil {
            headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier("HeaderView") as? RemindersListHeaderView
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "headerViewTapped:")
            headerView!.addGestureRecognizer(tapGestureRecognizer)
        }

        if let headerView = headerView {
            headerView.titleTextField.text = calendar.title
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
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        visibleHeaders[section] = view as? RemindersListHeaderView
    }
    
    func tableView(tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        visibleHeaders.removeValueForKey(section)
    }

}
