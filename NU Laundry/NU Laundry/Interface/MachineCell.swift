//
//  MachineCell.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class MachineCell: UITableViewCell {

    // MARK: - Interface

    @IBOutlet weak private var numberLabel: UILabel! {
        didSet {
            numberLabel.layer.cornerRadius = 5
            numberLabel.clipsToBounds = true
        }
    }
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!

    // MARK: - Properties

    var machine: Machine? = nil {
        didSet {
            guard let machine = machine else { return }

            numberLabel.text = machine.number.description
            titleLabel.text =  machine.status.title
            detailLabel.text = machine.status.detail?.uppercased()

            switch machine.status {
            case .active:
                numberLabel.backgroundColor = UIColor.negative
            case .available:
                numberLabel.backgroundColor = UIColor.postive
            case .cycleEnded:
                numberLabel.backgroundColor = UIColor.orange
            case .outOfService:
                numberLabel.backgroundColor = UIColor.black
            case .extendedCycle:
                numberLabel.backgroundColor = UIColor.negative
            case .unknown:
                numberLabel.backgroundColor = UIColor.lightGray
            }
        }
    }

}
