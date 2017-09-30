//
//  LocationCell.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/30/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class LocationCell: UITableViewCell {

    // MARK: - Interface

    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var washersLabel: UILabel! {
        didSet {
            washersLabel.clipsToBounds = true
            washersLabel.layer.cornerRadius = 5
        }
    }
    @IBOutlet weak private var dryersLabel: UILabel! {
        didSet {
            dryersLabel.clipsToBounds = true
            dryersLabel.layer.cornerRadius = 5
        }
    }

    // MARK: - Properties

    var location: Location? = nil {
        didSet {
            guard let location = location else { return }
            titleLabel.text = location.name

            washersLabel.text = location.availableWashers.description + " W"
            dryersLabel.text = location.availableDryers.description + " D"

            if location.availableWashers > 0 {
                washersLabel.backgroundColor = UIColor.postive
            } else {
                washersLabel.backgroundColor = UIColor.negative
            }

            if location.availableDryers > 0 {
                dryersLabel.backgroundColor = UIColor.postive
            } else {
                dryersLabel.backgroundColor = UIColor.negative
            }
        }
    }

    // MARK: - Colors

    override func setSelected(_ selected: Bool, animated: Bool) {
        let dryersColor = dryersLabel.backgroundColor
        let washersColor = washersLabel.backgroundColor
        super.setSelected(selected, animated: animated)
        dryersLabel.backgroundColor = dryersColor
        washersLabel.backgroundColor = washersColor
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let dryersColor = dryersLabel.backgroundColor
        let washersColor = washersLabel.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        dryersLabel.backgroundColor = dryersColor
        washersLabel.backgroundColor = washersColor
    }

}
