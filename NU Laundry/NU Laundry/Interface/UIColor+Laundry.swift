//
//  UIColor+Laundry.swift
//  NU Laundry
//
//  Created by Andrew Finke on 10/1/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

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
