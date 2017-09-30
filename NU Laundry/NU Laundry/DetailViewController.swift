//
//  DetailViewController.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class DetailViewController: UICollectionViewController {

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
                self.collectionView?.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        print(234)
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(234)
        if section == 0 {
            return washers.count
        } else {
            return dryers.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let machine: Machine
        if indexPath.section == 0 {
            machine = washers[indexPath.row]
        } else {
            machine = dryers[indexPath.row]
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? MachineCell else {
            fatalError()
        }
        cell.machine = machine
print(32)
        return cell
    }

}

