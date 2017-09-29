//
//  AppDelegate.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        guard let splitViewController = window?.rootViewController as? UISplitViewController else {
            fatalError()
        }
        splitViewController.preferredDisplayMode = .allVisible

        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = UIColor(red: 73.0/255.0, green: 46.0/255.0, blue: 127.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().prefersLargeTitles = true
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .foregroundColor: UIColor.white
            ]
        }

        return true
    }

}

