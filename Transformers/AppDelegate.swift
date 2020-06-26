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
    var flowController: FlowController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow()
        window?.bounds = UIScreen.main.bounds
        window?.backgroundColor = .white
        
        flowController = FlowController()
        window?.rootViewController = flowController?.rootViewController
        
        window?.makeKeyAndVisible()
        
        return true
    }
    
}
