//
//  MachineCell.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class MachineCell: UICollectionViewCell {

    // MARK: - Properties

    var machine: Machine? = nil {
        didSet {
            machineView.machine = machine
        }
    }
    
    @IBOutlet weak private var machineView: MachineView!

}
