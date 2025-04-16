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
        
        // Check if user is logged in
        if UserDefaultsManager.shared.isLoggedIn {
            // User is logged in, show main tab bar
            let mainTabBar = MainTabBarController()
            window?.rootViewController = mainTabBar
        } else {
            // User is not logged in, show login screen
            let loginVC = LoginViewController()
            let navController = UINavigationController(rootViewController: loginVC)
            window?.rootViewController = navController
        }
        
        window?.makeKeyAndVisible()
        return true
    }
}
