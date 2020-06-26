//
//  Transformer.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-26.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

enum Team: String, Codable {
    case autobots = "A"
    case decepticons = "D"
}

struct Transformer: Codable {
    var id: String?
    var name: String
    var team: Team
    var teamIcon: String?
    var rank: Int
    var strength: Int
    var intellegence: Int
    var speek: Int
    var endurance: Int
    var courage: Int
    var firepower: Int
    var skill: Int
}

extension Transformer {
    // custom initializer that omits teamIcon and optionally id from the parameter list
    init(id: String? = nil, name: String, team: Team, rank: Int, strength: Int, intellegence: Int, speek: Int, endurance: Int, courage: Int, firepower: Int, skill: Int) {
        self.id = id
        self.name = name
        self.team = team
        self.rank = rank
        self.strength = strength
        self.intellegence = intellegence
        self.speek = speek
        self.endurance = endurance
        self.courage = courage
        self.firepower = firepower
        self.skill = skill
    }
}


typealias TransformerInput = Transformer

extension TransformerInput {
    init(from source: Transformer, excludingId: Bool = false) {
        self.teamIcon = nil
        self.id = excludingId ? nil : source.id
        self.name = source.name
        self.team = source.team
        self.rank = source.rank
        self.strength = source.strength
        self.intellegence = source.intellegence
        self.speek = source.speek
        self.endurance = source.endurance
        self.courage = source.courage
        self.firepower = source.firepower
        self.skill = source.skill
    }
    
}
