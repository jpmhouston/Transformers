//
//  Transformer.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-26.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

struct Transformer: Codable, Hashable {
    
    enum Team: String, Codable {
        case autobots = "A"
        case decepticons = "D"
    }
    
    var id: String?
    var name: String
    var team: Team
    var teamIcon: String?
    var rank: Int
    var strength: Int
    var intelligence: Int
    var speed: Int
    var endurance: Int
    var courage: Int
    var firepower: Int
    var skill: Int
    
    var rating: Int {
        strength + intelligence + speed + endurance + firepower
    }
    
    var teamName: String {
        // decided team names shouldn't be localized, but if so would use code like this:
        // (team == .autobots) ? NSLocalizedString("Autobots", comment: "") : NSLocalizedString("Decepticons", comment: "")
        (team == .autobots) ? "Autobots" : "Decepticons"
    }
    
    var nameIncludingTeam: String {
        // would localize this string concatination if it was used in the UI not just assertions:
        // let formatStr = (team == .autobots) ? NSLocalizedString("Autobot %@", comment: "") : NSLocalizedString("Decepticon %@", comment: "")
        let formatStr = (team == .autobots) ? "Autobot %@" : "Decepticon %@"
        return String(format: formatStr, name)
    }
    
    var isSpecial: Bool {
        // decided these special transformer names shouldn't be localized either
        hasMatchingName("Optimus Prime") || hasMatchingName("Predaking")
    }
    
    func hasMatchingName(_ name: String) -> Bool {
        self.name.caseInsensitiveCompare(name) == ComparisonResult.orderedSame
    }
    
    func hasMatchingId(_ id: String) -> Bool {
        self.id == id
    }
    
    enum Sorting: String {
        case name, nameDescending
        case team, teamDescending
        case rank, rankDescending
        case rating, ratingDescending
    }
    
    static func orderWithCriteria(_ criteria: [Sorting]) -> (Transformer, Transformer) -> Bool {
        // return a function that's `(Transformer, Transformer) -> Bool` which can be passed to `sort(by:)`
        return {
            compareWithCriteria(criteria, lhs: $0, rhs: $1) != .orderedDescending
        }
    }
    
    static func compareWithCriteria(_ criteria: [Sorting], lhs: Transformer, rhs: Transformer) -> ComparisonResult {
        for criterion in criteria {                 // yes, criterion is the singluar of criteria
            let comparison: ComparisonResult
            var reverse = false
            switch criterion {
            case .nameDescending:
                reverse = true
                fallthrough
            case .name:
                comparison = lhs.name.compare(rhs.name)
                
            case .teamDescending:
                reverse = true
                fallthrough
            case .team:
                switch (lhs.team, rhs.team) { // when ascending sort autobots first
                case (Team.autobots, Team.autobots), (Team.decepticons, Team.decepticons): comparison = .orderedSame
                case (Team.autobots, Team.decepticons): comparison = .orderedAscending
                case (Team.decepticons, Team.autobots): comparison = .orderedDescending
                }
                
            case .rankDescending:
                reverse = true
                fallthrough
            case .rank:
                let lhsRank = lhs.rank
                let rhsRank = rhs.rank
                comparison = lhsRank == rhsRank ? .orderedSame : (lhsRank < rhsRank ? .orderedAscending : .orderedDescending)
                
            case .ratingDescending:
                reverse = true
                fallthrough
            case .rating:
                let lhsRating = lhs.rating
                let rhsRating = rhs.rating
                comparison = lhsRating == rhsRating ? .orderedSame : (lhsRating < rhsRating ? .orderedAscending : .orderedDescending)
            }
            
            switch comparison {
            case .orderedAscending:
                return reverse ? .orderedDescending : .orderedAscending
            case .orderedDescending:
                return reverse ? .orderedAscending : .orderedDescending
            default:
                continue // compare by next criterion
            }
        }
        
        // if everything equal, compare id's
        if lhs.id != nil && rhs.id == nil {
            return .orderedAscending
        } else if lhs.id == nil && rhs.id != nil {
            return .orderedDescending
        } else if lhs.id! != rhs.id! { // all cases of either one or the other nil are detected above
            return lhs.id! < rhs.id! ? .orderedAscending : .orderedDescending
        } else {
            return .orderedSame // if id's equal too, then who cares pick either t or f
        }
    }
    
}

extension Transformer {
    // custom initializer that omits teamIcon & optionally omits id from the parameter list
    init(id: String? = nil, name: String, team: Team, rank: Int, strength: Int, intelligence: Int, speed: Int, endurance: Int, courage: Int, firepower: Int, skill: Int) {
        self.id = id
        self.name = name
        self.team = team
        self.rank = rank
        self.strength = strength
        self.intelligence = intelligence
        self.speed = speed
        self.endurance = endurance
        self.courage = courage
        self.firepower = firepower
        self.skill = skill
    }
    
    init(copiedFrom source: Transformer, includingId: Bool = false) {
        self.id = includingId ? source.id : nil
        self.name = source.name
        self.team = source.team
        self.teamIcon = source.teamIcon
        self.rank = source.rank
        self.strength = source.strength
        self.intelligence = source.intelligence
        self.speed = source.speed
        self.endurance = source.endurance
        self.courage = source.courage
        self.firepower = source.firepower
        self.skill = source.skill
    }
    
    init(copiedFrom source: Transformer, replacingId newId: String?) {
        self.id = newId
        self.name = source.name
        self.team = source.team
        self.teamIcon = source.teamIcon
        self.rank = source.rank
        self.strength = source.strength
        self.intelligence = source.intelligence
        self.speed = source.speed
        self.endurance = source.endurance
        self.courage = source.courage
        self.firepower = source.firepower
        self.skill = source.skill
    }
    
    init() {
        self.id = nil
        self.name = ""
        self.team = .autobots
        self.rank = 0
        self.strength = 0
        self.intelligence = 0
        self.speed = 0
        self.endurance = 0
        self.courage = 0
        self.firepower = 0
        self.skill = 0
    }
}


typealias TransformerInput = Transformer

extension TransformerInput {
    init(sourcedFrom source: Transformer, includingId: Bool = true) {
        self.id = includingId ? source.id : nil
        self.name = source.name
        self.team = source.team
        self.teamIcon = nil         // always nil
        self.rank = source.rank
        self.strength = source.strength
        self.intelligence = source.intelligence
        self.speed = source.speed
        self.endurance = source.endurance
        self.courage = source.courage
        self.firepower = source.firepower
        self.skill = source.skill
    }
    
}
