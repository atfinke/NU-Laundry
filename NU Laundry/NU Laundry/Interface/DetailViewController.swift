//
//  DetailViewController.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import UserNotifications

class DetailViewController: UITableViewController {

    // MARK: - Properties

    private var dryers = [Machine]()
    private var washers = [Machine]()
    
    var detailItem: Location? {
        didSet {
            reloadMachines()
            title = detailItem?.name
        }
    }

    // MARK: - Machines

    private func machine(for indexPath: IndexPath) -> Machine {
        if indexPath.section == 0 {
            return washers[indexPath.row]
        } else {
            return dryers[indexPath.row]
        }
    }

    @objc private func reloadMachines() {
        guard let location = detailItem else { return }
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        LaundryFetcher.fetchMachines(for: location) { (washers, dryers, error) in
            DispatchQueue.main.async {
                if let _ = error {
                    self.washers = []
                    self.dryers = []
                } else if let washers = washers, let dryers = dryers {
                    self.washers = washers
                    self.dryers = dryers
                } else {

                }
                self.tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let machine = self.machine(for: indexPath)
        guard let locationName = detailItem?.name, case let Machine.Status.active(time, _) = machine.status else {
            return []
        }

        func presentNotificationAlert() {
            let alertController = UIAlertController(title: "Issue Scheduling Alert", message: "There was a problem scheduling the reminder notification", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        }

        let remindAction = UITableViewRowAction(style: .default, title: "Remind Me") { (_, indexPath) in
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert]) { (granted, error) in
                if granted {
                    let content = UNMutableNotificationContent()
                    content.title = "Laundry Cycle Almost Done"

                    let identifier = locationName + machine.number.description
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(time * 60), repeats: false)
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                    center.add(request, withCompletionHandler: { (error) in
                        if error != nil {
                            presentNotificationAlert()
                        }
                    })
                } else {
                    presentNotificationAlert()
                }
            }
        }
        remindAction.backgroundColor = view.tintColor
        
        return [remindAction]
    }

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

