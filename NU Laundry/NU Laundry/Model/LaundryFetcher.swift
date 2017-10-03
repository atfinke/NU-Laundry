//
//  LaundryFetcher.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import SwiftSoup
import Crashlytics

struct LaundryFetcher {

    // MARK: - Types

    enum ParsingError: Error {
        case unknownError
        case connectionError
        case elementsMismatchError
        case locationURLError
        case locationDetailError
        case availabilityIndexError
        case availabilityLengthError

        case machineDetailError
        case machineListError

        case serverSideError
    }

    // MARK: - Locations

    static func fetchLocations(completion: @escaping ((_ locations: [Location]?, _ error: ParsingError?) -> Void)) {
        let url = URL(string: "http://classic.laundryview.com/lvs.php?s=328")!

        var urlRequest = URLRequest(url: url,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 10.0)

        //swiftlint:disable:next line_length
        urlRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Safari/604.1.38 \(Double(arc4random()).truncatingRemainder(dividingBy: pow(10, 3)))", forHTTPHeaderField: "User-Agent")

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, _, error) in
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(nil, .connectionError)
                return
            }
            do {
                let locations = try self.parse(locationsHTML: html)
                completion(locations, nil)
            } catch {
                if let error = error as? ParsingError {
                    completion(nil, error)
                } else {
                    completion(nil, .unknownError)
                }
            }
        }
        dataTask.resume()
    }

    private static func parse(locationsHTML: String) throws -> [Location] {
        let locationElements: [Element]
        let locationAvailability: [Element]
        do {
            let document = try SwiftSoup.parse(locationsHTML)
            locationElements = try document.select("a[href*='laundry_room.php?lr']").array()
            locationAvailability = try document.select("span[class*='user-avail'").array()
        } catch {
            throw error
        }

        guard locationElements.count == locationAvailability.count else {
            throw ParsingError.elementsMismatchError
        }

        var locations = [Location]()
        for (index, locationElement) in locationElements.enumerated() {
            do {
                let locationName = try locationElement.text().capitalized
                    .replacingOccurrences(of: "1St", with: "1st")
                    .replacingOccurrences(of: "2Nd", with: "2nd")
                    .replacingOccurrences(of: "3Rd", with: "3rd")
                    .replacingOccurrences(of: "4Th", with: "4th")
                    .replacingOccurrences(of: "Parc ", with: "")

                let lastComponentPath = try locationElement.attr("href")
                guard let url = URL(string: "http://classic.laundryview.com/" + lastComponentPath) else {
                    throw ParsingError.locationURLError
                }

                let (washers, dryers) = try parse(locationAvailability: locationAvailability[index].text())
                let location = Location(url: url,
                                        name: locationName,
                                        availableDryers: dryers,
                                        availableWashers: washers)
                locations.append(location)
            } catch {
                throw ParsingError.locationDetailError
            }
        }

        guard locations.count > 10 else {
            Answers.logCustomEvent(withName: "Server Side Error", customAttributes: ["HTML": locationsHTML])
            throw ParsingError.serverSideError
        }

        return locations.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.name < rhs.name
        })
    }

    private static func parse(locationAvailability: String) throws -> (washers: Int, dryers: Int) {
        guard locationAvailability.count > 5 else {
            throw ParsingError.availabilityLengthError
        }

        let startIndex = locationAvailability.index(locationAvailability.startIndex, offsetBy: 1)
        let endIndex = locationAvailability.index(locationAvailability.endIndex, offsetBy: -2)
        let adjustedString = locationAvailability[startIndex...endIndex]

        guard let washingIndex = adjustedString.range(of: " W")?.lowerBound,
            let splitIndex = adjustedString.range(of: "/ ")?.upperBound,
            let dryerIndex = adjustedString.range(of: " D")?.lowerBound,
            let washers = Int(adjustedString[adjustedString.startIndex...washingIndex]),
            let dryers = Int(adjustedString[splitIndex...dryerIndex].replacingOccurrences(of: " ", with: "")) else {
                throw ParsingError.availabilityIndexError
        }

        return (washers, dryers)
    }

    // MARK: - Machines

    static func fetchMachines(for location: Location,
                              completion: @escaping (([Machine]?, [Machine]?, ParsingError?) -> Void)) {

        var urlRequest = URLRequest(url: location.url,
                                    cachePolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 10.0)

        //swiftlint:disable:next line_length
        urlRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Safari/604.1.38 \(Double(arc4random()).truncatingRemainder(dividingBy: pow(10, 3)))", forHTTPHeaderField: "User-Agent")

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, _, error) in
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(nil, nil, .connectionError)
                return
            }
            do {
                let (washers, dryers) = try self.parse(machinesHTML: html)
                completion(washers, dryers, nil)
            } catch {
                if let error = error as? ParsingError {
                    completion(nil, nil, error)
                } else {
                    completion(nil, nil, .unknownError)
                }
            }
        }
        dataTask.resume()
    }

    private static func parse(machinesHTML: String) throws -> (washers: [Machine], dryers: [Machine]) {
        do {
            let document = try SwiftSoup.parse(machinesHTML)
            let machinesTable = try document.select("#classic_monitor> table > tbody > tr")
            let washersTableRows = try machinesTable.select("td:nth-child(1) > table > tbody").select("tr").array()
            let dryerTableRows = try machinesTable.select("td:nth-child(2) > table > tbody").select("tr").array()

            let washers = parse(machinesTable: washersTableRows)
            let dryers = parse(machinesTable: dryerTableRows)

            return (washers: washers, dryers: dryers)
        } catch {
            throw error
        }
    }

    private static func parse(machinesTable: [Element]) -> [Machine] {
        var machines = [Machine]()
        for i in 0..<machinesTable.count / 4 {
            let attributesRow = machinesTable[i*4]
            do {
                let statusRow = try machinesTable[i*4 + 3].select("td > div > span").text()
                var status = Machine.Status.unknown
                if let index = statusRow.range(of: "remaining ")?.upperBound,
                    let endIndex = statusRow.range(of: " min")?.lowerBound,
                    let time = Int(statusRow[index...endIndex].replacingOccurrences(of: " ", with: "")) {

                    var progress = 0.0
                    let selectorString = "td.bgruntime > table > tbody > tr > td > table > tbody > tr > td > img"
                    if let progressBarWidth = try? attributesRow.select(selectorString).attr("width"),
                        let progressBarValue = Double(progressBarWidth) {
                        progress = progressBarValue / 240
                    }

                    status = .active(time: time, progress: progress)
                } else if let index = statusRow.range(of: "cycle ended ")?.upperBound,
                    let endIndex = statusRow.range(of: " minutes ago")?.lowerBound,
                    let time = Int(statusRow[index...endIndex].replacingOccurrences(of: " ", with: "")) {
                    status = .cycleEnded(time: time)
                } else if let index = statusRow.range(of: "extended cycle running for ")?.upperBound,
                    let endIndex = statusRow.range(of: " mins")?.lowerBound,
                    let time = Int(statusRow[index...endIndex].replacingOccurrences(of: " ", with: "")) {
                    status = .extendedCycle(time: time)
                } else if statusRow.contains("out of service") {
                    status = .outOfService
                } else if statusRow.contains("available") {
                    status = .available
                } else {
                    print(statusRow)
                }

                let numberString = try attributesRow.select("td.bgdesc").text()
                guard let number = Int(numberString) else {
                    throw ParsingError.machineDetailError
                }

                let machine = Machine(number: number, status: status)
                machines.append(machine)
            } catch {
                print(error)
            }
        }
        return machines
    }
}
