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
    
    func configure(name: String, teamIconURL: String?, isSpecial: Bool, rank: Int, rating: Int, benched: Bool) {
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
        // i think i'm going to use SDWebImage cocoapod for loading the team icon
        //      pod 'SDWebImage', '~> 5.0'
        //if let url = teamIconURL {
        //    teamIcon.sd_setImage(with: URL(string: teamIconURL))
        //} else {
        //    teamIcon.image = nil
        //}
        //
        // or maybe Kingfisher
        //      pod 'Kingfisher', '~> 5.0'
        //if let url = teamIconURL {
        //    teamIcon.kf.indicatorType = .activity
        //    teamIcon.kf.setImage(with: URL(string: teamIconURL), options: [
        //        .processor(DownsamplingImageProcessor(size: imageView.bounds.size),
        //        .scaleFactor(UIScreen.main.scale),
        //        .transition(.fade(1))])
        //} else {
        //    teamIcon.image = nil
        //}
    }
    
}
