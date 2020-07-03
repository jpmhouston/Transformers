//
//  TransformerListCell.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-28.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import UIKit

class TransformerListCell: UITableViewCell {
    
    @IBOutlet var teamIcon: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var star: UIImageView!
    @IBOutlet var joinedBenchedIcon: UIImageView!
    @IBOutlet var rankValue: UILabel!
    @IBOutlet var ratingValue: UILabel!
    
    var transformerId: String!
    var isBenched: Bool = false
    
    func configure(name: String, teamIcon: String?, isSpecial: Bool, rank: Int, rating: Int, benched: Bool) {
        nameLabel.text = name
        star.isHidden = !isSpecial
        rankValue.text = String(rank)
        ratingValue.text = String(rating)
        isBenched = benched
        if benched {
            joinedBenchedIcon.image = UIImage(named: "BenchIcon")
        } else {
            joinedBenchedIcon.image = UIImage(named: "FightIcon")
        }
        self.teamIcon.setTransformerIcon(withURLString: teamIcon)
    }
    
}
