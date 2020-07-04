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
            if let vc: T = nav.viewControllers.firstAs() {
                return vc
            }
        } else if let split = self as? UISplitViewController {
            if let vc: T = split.viewControllers.firstMap({ $0.locateViewControllerByType() }) {
                return vc
            }
        }
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

extension Sequence {
    // see recent thread https://forums.swift.org/t/adding-firstas-to-sequence/36665/30
    
    func firstAs<T>(_ type: T.Type = T.self) -> T? {
        first(where: { $0 is T }) as? T
    }
    
    func firstMap<T>(_ transform: (Element) throws -> T?) rethrows -> T? {
        for element in self {
            if let transformed = try transform(element) {
                return transformed
            }
        }
        return nil
    }
    
}
