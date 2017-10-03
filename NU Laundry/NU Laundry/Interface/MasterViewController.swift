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
    private var locations = [Location]() {
        didSet {
            favoriteLocations = locations.filter { location -> Bool in
                return isLocationFavorite(location)
            }
        }
    }
    private var favoriteLocations = [Location]()
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

    private func location(for indexPath: IndexPath) -> Location {
        let location: Location
        if isFiltering() {
            location = filteredLocations[indexPath.row]
        } else if indexPath.section == 0 {
            location = favoriteLocations[indexPath.row]
        } else {
            location = locations[indexPath.row]
        }
        return location
    }

    private func startReloadingLocations() {
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.startReloadingLocations()
        }
        reloadLocations()
    }

    @objc private func reloadLocations() {
        guard !isEditing else { return }

        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }

        LaundryFetcher.fetchLocations { (locations, error) in
            DispatchQueue.main.async {
                var shouldReloadAll = true
                if let locations = locations, !locations.isEmpty {
                    shouldReloadAll = self.locations.count != locations.count
                    self.locations = locations

                    Answers.logCustomEvent(withName: "Updated Locations", customAttributes: nil)
                } else {
                    self.locations = []

                    var message = "An issue occured when trying to update the laundry infomation."
                    if error == .serverSideError {
                        message = "Laundry service information is currently unavailable. Check back later."
                    }

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

    // MARK: - Favorites

    func isLocationFavorite(_ location: Location) -> Bool {
        return UserDefaults.standard.bool(forKey: location.name)
    }

    func toggleLocationFavoriteStatus(_ location: Location) {
        let currentStatus = UserDefaults.standard.bool(forKey: location.name)
        UserDefaults.standard.set(!currentStatus, forKey: location.name)

        favoriteLocations = locations.filter { location -> Bool in
            return isLocationFavorite(location)
        }

        Answers.logCustomEvent(withName: "Toggled Location Favorite", customAttributes: nil)
    }

    override func tableView(_ tableView: UITableView,
                            editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        guard !isFiltering() else { return [] }

        let location = self.location(for: indexPath)
        let isFavorite = isLocationFavorite(location)
        let actionString = isFavorite ? "Remove From Favorites" : "Favorite"

        let favoriteAction = UITableViewRowAction(style: .default, title: actionString) { (_, _) in
            let feedback = UISelectionFeedbackGenerator()
            feedback.selectionChanged()

            self.toggleLocationFavoriteStatus(location)
            self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
        }
        favoriteAction.backgroundColor = isFavorite ? UIColor.red : view.tintColor

        return [favoriteAction]
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering() {
            return 1
        } else {
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredLocations.count
        } else if section == 0 {
            return favoriteLocations.count
        } else {
            return locations.count
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isFiltering() {
            return nil
        } else if section == 0 {
            if favoriteLocations.isEmpty {
                return nil
            } else {
                return "Favorites"
            }
        } else {
            return "All Locations"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if locations.isEmpty || section == 0 {
            return nil
        } else {
            return "Swipe left on a location to favorite it."
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? LocationCell else {
            fatalError()
        }

        cell.location = self.location(for: indexPath)
        return cell
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail",
            let controller = (segue.destination as? UINavigationController)?.topViewController as? DetailViewController,
            let indexPath = tableView.indexPathForSelectedRow {

            controller.detailItem = self.location(for: indexPath)
        }
    }
}
