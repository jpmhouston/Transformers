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
    
    func configure(name: String, teamIconURL: URL?, isSpecial: Bool, rank: Int, rating: Int, benched: Bool) {
        //teamIcon.image = ...
        nameLabel.text = name
        star.isHidden = !isSpecial
        rankValue.text = String(rank)
        ratingValue.text = String(rating)
        if benched {
            joinedBenchedIcon.image = UIImage(named: "BenchIcon")
        } else {
            joinedBenchedIcon.image = UIImage(named: "FightIcon")
        }
    }
    
}
