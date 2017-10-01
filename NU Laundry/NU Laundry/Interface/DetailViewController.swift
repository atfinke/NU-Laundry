//
//  DetailViewController.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import UserNotifications

import Crashlytics

class DetailViewController: UITableViewController {

    // MARK: - Properties

    private var reloadTimer: Timer?
    private var dryers = [Machine]()
    private var washers = [Machine]()

    var detailItem: Location? {
        didSet {
            reloadMachines()
            title = detailItem?.name
        }
    }

    // MARK: - View Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startReloadingMachines()

        //swiftlint:disable discarded_notification_center_observer
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground,
                                               object: nil,
                                               queue: nil) { [weak self] _ in
            self?.startReloadingMachines()
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("UIBackgroundFetch"),
                                               object: nil,
                                               queue: nil) { [weak self] _ in
            // Don't start timer
            self?.reloadMachines()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        reloadTimer?.invalidate()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Machines

    private func machine(for indexPath: IndexPath) -> Machine {
        if indexPath.section == 0 {
            return washers[indexPath.row]
        } else {
            return dryers[indexPath.row]
        }
    }

    private func startReloadingMachines() {
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.reloadMachines()
        }
        reloadMachines()
    }

    @objc private func reloadMachines() {
        guard let location = detailItem, !isEditing else { return }

        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }

        LaundryFetcher.fetchMachines(for: location) { (washers, dryers, _) in
            DispatchQueue.main.async {
                var shouldReloadAll = true
                if let washers = washers, let dryers = dryers, !washers.isEmpty, !dryers.isEmpty {
                    shouldReloadAll = self.washers.count != washers.count || self.dryers.count != dryers.count
                    self.washers = washers
                    self.dryers = dryers

                    Answers.logCustomEvent(withName: "Updated Machines", customAttributes: nil)
                } else {
                    self.washers = []
                    self.dryers = []

                    let message = "An issue occured when trying to update the laundry infomation."
                    let alertController = UIAlertController(title: "Connection Issue",
                                                            message: message,
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
                        self.startReloadingMachines()
                    }))
                    self.present(alertController, animated: true, completion: nil)

                    self.reloadTimer?.invalidate()
                    Answers.logCustomEvent(withName: "Machines Error", customAttributes: nil)
                }

                if shouldReloadAll {
                    self.tableView.reloadData()
                } else {
                    self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows ?? [], with: .none)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }

    // MARK: - Notifications

    private func scheduleNotification(machine: Machine, machineType: String, time: Int) {
        guard let locationName = detailItem?.name else { return }

        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default()
        content.title = "Laundry Reminder"
        content.body = "\(machineType) \(machine.number.description)'s cycle is almost done."

        let identifier = locationName + machine.number.description
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(time * 60), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if error != nil {
                self.presentNotificationErrorAlert()
            }
        })
        Answers.logCustomEvent(withName: "Scheduled Notification", customAttributes: nil)
    }

    private func presentNotificationErrorAlert() {

        let message = "There was a problem scheduling the reminder notification."
        let alertController = UIAlertController(title: "Issue Scheduling Alert",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }

        Answers.logCustomEvent(withName: "Scheduled Notification Error", customAttributes: nil)
    }

    override func tableView(_ tableView: UITableView,
                            editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let machine = self.machine(for: indexPath)
        guard case let Machine.Status.active(time, _) = machine.status else {
            return []
        }

        let remindAction = UITableViewRowAction(style: .default, title: "Remind Me") { (_, indexPath) in
            let feedback = UISelectionFeedbackGenerator()
            feedback.selectionChanged()

            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, _) in
                if granted {
                    let machineType = indexPath.section == 0 ? "Washer" : "Dryer"
                    self.scheduleNotification(machine: machine, machineType: machineType, time: time)
                } else {
                    self.presentNotificationErrorAlert()
                }
            }
        }
        remindAction.backgroundColor = view.tintColor

        return [remindAction]
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && !washers.isEmpty {
            return "Washers"
        } else if section == 1 && !dryers.isEmpty {
            return "Dryers"
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 1 else {
            return nil
        }

        let activeMachines = !(washers + dryers).filter({ machine -> Bool in
            if case Machine.Status.active(_) = machine.status {
                return true
            } else {
                return false
            }
        }).isEmpty

        guard activeMachines else {
            return nil
        }

        //swiftlint:disable:next line_length
        return "Swipe left on an active washing machine to schedule a reminder notification for when its cycle is almost done."
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return washers.count
        } else {
            return dryers.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? MachineCell else {
            fatalError()
        }
        cell.machine = machine(for: indexPath)
        return cell
    }

}
