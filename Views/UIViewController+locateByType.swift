//
//  UIViewController+locateByType.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-28.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func locateViewControllerByType<T>() -> T? {
        if let vc = self as? T {
            return vc
        } else if let nav = self as? UINavigationController {
            if let vc = nav.viewControllers.first(where: { $0 is T }) as? T {
                return vc
            }
        }
        // TODO: add cases for splitviewcontrollers, etc as needed
        return nil
    }
    
    func locateChildViewControllerByType<T>() -> T? {
        if let vc = children.first(where: { $0 is T }) as? T {
            return vc
        }
        return nil
    }
    
    func parentChildViewControllerByType<T>() -> T? {
        if let vc = parent as? T {
            return vc
        }
        return nil
    }
    
}
