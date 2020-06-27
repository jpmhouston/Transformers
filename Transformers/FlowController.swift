//
//  FlowController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-24.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//
//  I prefer something other than the app delegate to own and setup objects
//  such as view controllers and data/network managers. In a more complex app
//  I'd want to abstract those two away from each other as well, allow
//  the option of an alternate app target divorced from initial platform UI,
//  be it another platform or perhaps even command-line interface to assist
//  backend testing.
//
//  I'd also prefer a root flow controller and children for major sections of
//  the app, however going with only 1 for this.
//

import UIKit

class FlowController {
    
    var rootViewController: UIViewController
    var dataController: DataController
    var networkUtility: NetworkUtility
    
    init() {
        dataController = DataController()
        networkUtility = NetworkUtility()
        networkUtility.delegate = dataController
        
        rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .blue
    }
    
    // public funcs to be called from view controllers to handle transitions
    // to remove that logic and interdependence from the view controllers themselves
    
    // ...
}
