//
//  Machine.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

struct Machine {

    // MARK: - Types

    enum Status {

        case available
        case active(time: Int, progress: Double)
        case cycleEnded(time: Int)
        case outOfService
        case extendedCycle(time: Int)
        case unknown

        // MARK: - Properties

        var title: String  {
            switch self {
            case .available:  return "Available"
            case .active(_, _): return "In Use"
            case .cycleEnded(_):  return "Cycle Ended"
            case .outOfService: return "Out Of Service"
            case .extendedCycle(_): return "Running Extended Cycle"
            case .unknown: return "Unknown"
            }
        }

        var detail: String?  {
            switch self {
            case .available: return nil
            case .active(let time, _): return "\(time) Min Left"
            case .cycleEnded(let time):  return "\(time) Min Ago"
            case .outOfService: return nil
            case .extendedCycle(_): return nil
            case .unknown: return nil
            }
        }
    }

    // MARK: - Properties

    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    let number: Int
    let status: Status
}
