//
//  FlowController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-24.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit

class FlowController {
    
    public var rootViewController: UIViewController?
    
    init() {
        rootViewController = UIViewController()
        rootViewController?.view.backgroundColor = .blue
    }
    
    // public funcs to be called from view controllers to handle transitions
    // to remove that logic and interdependence from the view controllers themselves
    
}
