//
//  UIImageView+loadIcon.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-07-02.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit
import Kingfisher

// using a cocoapod for image loading & caching, i hope that's not against the rules
// (assuming ui frameworks mentioned was referring to reactnative / flutter etc.)

extension UIImageView {
    
    func setTransformerIcon(withURLString urlString: String?) {
        if let urlString = urlString, let url = URL(string: urlString) {
            kf.setImage(with: url, options: [
                    .processor(DownsamplingImageProcessor(size: bounds.size)),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(0.25))
                ], completionHandler: { result in
                    let _ = result
                    //print("image from \(urlString)\n\(result)\n")
                })
        } else {
            image = nil
        }
    }
    
}
