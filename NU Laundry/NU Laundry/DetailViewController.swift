//
//  DetailViewController.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class DetailViewController: UITableViewController {

    // MARK: - Properties

    private let dataRefreshControl = UIRefreshControl()

    private var dryers = [Machine]()
    private var washers = [Machine]()
    
    var detailItem: Location? {
        didSet {
            reloadMachines()
            title = detailItem?.name
        }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = nil

        dataRefreshControl.tintColor = UIColor.white
        dataRefreshControl.addTarget(self, action: #selector(reloadMachines), for: .valueChanged)
        tableView.refreshControl = dataRefreshControl
    }

    // MARK: - Machines

    @objc private func reloadMachines() {
        guard let location = detailItem else { return }
        DispatchQueue.main.async {
            self.dataRefreshControl.beginRefreshing()
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
                self.dataRefreshControl.endRefreshing()
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
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
        let machine: Machine
        if indexPath.section == 0 {
            machine = washers[indexPath.row]
        } else {
            machine = dryers[indexPath.row]
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? MachineCell else {
            fatalError()
        }
        cell.text(number: machine.number,
                  title: machine.status.title,
                  detail: machine.status.detail)

        return cell
    }

}

