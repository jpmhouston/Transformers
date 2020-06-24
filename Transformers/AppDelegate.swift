//
//  AppDelegate.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-23.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window : UIWindow?
    var rootViewController: UIViewController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        rootViewController = UIViewController()
        
        window = UIWindow()
        window?.bounds = UIScreen.main.bounds
        window?.backgroundColor = .white
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        
        return true
    }

}

