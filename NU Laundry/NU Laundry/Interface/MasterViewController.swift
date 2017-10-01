//
//  MasterViewController.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import Crashlytics

class MasterViewController: UITableViewController, UISearchResultsUpdating {

    // MARK: - Properties

    private var reloadTimer: Timer?
    private var locations = [Location]()
    private var filteredLocations = [Location]()

    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        reloadLocations()

        if #available(iOS 11.0, *) {
            searchController.isActive = true
            searchController.searchResultsUpdater = self
            searchController.searchBar.tintColor = UIColor.white
            searchController.dimsBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = false

            navigationItem.searchController = searchController

            navigationItem.largeTitleDisplayMode = .always
            navigationController?.navigationBar.prefersLargeTitles = true
        }

        //swiftlint:disable discarded_notification_center_observer
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground,
                                               object: nil,
                                               queue: nil) { [weak self] _ in
            self?.startReloadingLocations()
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("UIBackgroundFetch"),
                                               object: nil,
                                               queue: nil) { [weak self] _ in
            // Don't start timer
            self?.reloadLocations()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)

        startReloadingLocations()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        reloadTimer?.invalidate()
    }

    // MARK: - UISearchResultsUpdating

    func isFiltering() -> Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }

    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text?.lowercased() {
            filteredLocations = locations.filter { (location) -> Bool in
                return location.name.lowercased().contains(text)
            }
        } else {
            filteredLocations = []
        }
        tableView.reloadData()
    }

    // MARK: - Locations

    private func startReloadingLocations() {
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.startReloadingLocations()
        }
        reloadLocations()
    }

    @objc private func reloadLocations() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }

        LaundryFetcher.fetchLocations { (locations, _) in
            DispatchQueue.main.async {
                var shouldReloadAll = true
                if let locations = locations, !locations.isEmpty {
                    shouldReloadAll = self.locations.count != locations.count
                    self.locations = locations

                    Answers.logCustomEvent(withName: "Updated Locations", customAttributes: nil)
                } else {
                    self.locations = []

                    let message = "An issue occured when trying to update the laundry infomation."
                    let alertController = UIAlertController(title: "Connection Issue",
                                                            message: message,
                                                            preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
                        self.reloadLocations()
                    }))
                    self.present(alertController, animated: true, completion: nil)

                    self.reloadTimer?.invalidate()
                    Answers.logCustomEvent(withName: "Locations Error", customAttributes: nil)
                }

                if shouldReloadAll {
                    self.tableView.reloadData()
                } else {
                    let selectedRow = self.tableView.indexPathForSelectedRow
                    self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows ?? [], with: .none)

                    self.tableView.selectRow(at: selectedRow,
                                             animated: false,
                                             scrollPosition: UITableViewScrollPosition.none)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredLocations.count
        } else {
            return locations.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? LocationCell else {
            fatalError()
        }

        let location: Location
        if isFiltering() {
            location = filteredLocations[indexPath.row]
        } else {
            location = locations[indexPath.row]
        }

        cell.location = location
        return cell
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail",
            let controller = (segue.destination as? UINavigationController)?.topViewController as? DetailViewController,

            let indexPath = tableView.indexPathForSelectedRow {
            let location: Location
            if isFiltering() {
                location = filteredLocations[indexPath.row]
            } else {
                location = locations[indexPath.row]
            }
            controller.detailItem = location
        }
    }
}
