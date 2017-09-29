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

    @IBOutlet weak private var numberLabel: UILabel!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    @IBOutlet weak private var noDetailTitleLabel: UILabel!

    // MARK: - Helpers

    func text(number: Int, title: String, detail: String?) {
        numberLabel.text = number.description
        titleLabel.text = title
        noDetailTitleLabel.text = title
        detailLabel.text = detail

        if detail != nil {
            detailLabel.alpha = 1.0
            titleLabel.alpha = 1.0
            noDetailTitleLabel.alpha = 0.0
        } else {
            detailLabel.alpha = 0.0
            titleLabel.alpha = 0.0
            noDetailTitleLabel.alpha = 1.0
        }
    }
}
