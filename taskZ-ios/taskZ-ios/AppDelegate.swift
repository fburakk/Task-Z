//
//  AppDelegate.swift
//  taskZ-ios
//
//  Created by Burak Köse on 22.03.2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)

        let initialViewController = ViewController()
        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()

        return true
    }
}
