//
//  MachineCell.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class MachineCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet weak private var numberLabel: UILabel! {
        didSet {
            numberLabel.layer.cornerRadius = 5
            numberLabel.clipsToBounds = true
        }
    }
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!

    var machine: Machine? = nil {
        didSet {
            guard let machine = machine else { return }

            numberLabel.text = machine.number.description
            titleLabel.text =  machine.status.title
            detailLabel.text = machine.status.detail?.uppercased()

            switch machine.status {
            case .active(_, _):
                numberLabel.backgroundColor = UIColor.negative
            case .available:
                numberLabel.backgroundColor = UIColor.postive
            case .cycleEnded(_):
                numberLabel.backgroundColor = UIColor.orange
            case .outOfService:
                numberLabel.backgroundColor = UIColor.black
            case .extendedCycle(_):
                numberLabel.backgroundColor = UIColor.negative
            case .unknown:
                numberLabel.backgroundColor = UIColor.lightGray
            }
        }
    }

}

extension UIColor {

    static var postive: UIColor {
        return UIColor(displayP3Red: 67.0/255.0,
                       green: 144.0/255.0,
                       blue: 78.0/255.0,
                       alpha: 1.0)
    }

    static var negative: UIColor {
        return UIColor(displayP3Red: 230.0/255.0,
                       green: 50.0/255.0,
                       blue: 35.0/255.0,
                       alpha: 1.0)
    }

}
