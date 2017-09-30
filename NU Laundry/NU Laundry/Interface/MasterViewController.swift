//
//  MasterViewController.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, UISearchResultsUpdating {

    // MARK: - Properties

    private var locations = [Location]()
    private var filteredLocations = [Location]()

    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        reloadLocations()

        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .always
        }
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.tintColor = UIColor.white
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.isActive = true

        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
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

    // MARK: - Rooms

    @objc private func reloadLocations() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        LaundryFetcher.fetchLocations { (locations, error) in
            DispatchQueue.main.async {
                if let _ = error {
                    self.locations = []
                } else if let locations = locations {
                    self.locations = locations
                }
                self.tableView.reloadData()
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
        if segue.identifier == "showDetail", let controller = (segue.destination as? UINavigationController)?.topViewController as? DetailViewController,
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

