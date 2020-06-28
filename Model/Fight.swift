//
//  Fight.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-26.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

extension Transformer {
    
    enum FightResult {
        case win, loss, tie, destruction
    }
    
    func fight(against opponent: Transformer) -> FightResult {
        // perhaps prevent transformers on the same team from fighting? currently its allowed
        
        if isSpecial && opponent.isSpecial {
            return .destruction
        } else if isSpecial {
            return .win
        } else if opponent.isSpecial {
            return .loss
        }
            
        else if courage >= opponent.courage + 4 {
            return .win
        } else if strength >= opponent.strength + 3 {
            return .win
        } else if skill >= opponent.skill + 3 {
            return .win
        } else if courage + 4 <= opponent.courage {
            return .loss
        } else if strength + 3 <= opponent.strength {
            return .loss
        } else if skill + 3 <= opponent.skill {
            return .loss
        }
        
        else if rating > opponent.rating {
            return .win
        } else if rating < opponent.rating {
            return .loss
        } else {
            return .tie
        }
    }
    
    // currently throw if an autobot is found amongst the decepticons battle team, or vice-versa
    // perhaps only make `battle(betweenTransformers:)` public and treat this as a fatalError
    // in the private `battle(betweenAutobots:andDecepticons:)`
    enum BattleError: Error {
        case traitorAutobot, traitorDecepticon
    }
    
    enum BattleResult {
        case autobotWin, decepticonWin, tie, destruction
    }
    
    static func battle(betweenTransformers transformers: [Transformer]) ->
        (result: BattleResult, rounds: Int, survivingAutobots: [Transformer], survivingDecepticons: [Transformer])
    {
        let autobots = transformers.filter { $0.team == .autobots }
        let decepticons = transformers.filter { $0.team == .decepticons }
        return try! battle(betweenAutobots: autobots, andDecepticons: decepticons)
    }
    
    static func battle(betweenAutobots autobots: [Transformer], andDecepticons decepticons: [Transformer]) throws ->
        (result: BattleResult, rounds: Int, survivingAutobots: [Transformer], survivingDecepticons: [Transformer])
    {
        guard autobots.contains(where: { $0.team == .decepticons }) == false else {
            throw BattleError.traitorDecepticon
        }
        guard decepticons.contains(where: { $0.team == .autobots }) == false else {
            throw BattleError.traitorAutobot
        }
        
        let rankSort = Transformer.orderWithCriteria([.rankDescending, .name])
        
        var autobotCombatants: [Transformer] = autobots.sorted(by: rankSort)
        var decepticonCombatants: [Transformer] = decepticons.sorted(by: rankSort)
        var autobotSurvivors: [Transformer] = []
        var decepticonSurvivors: [Transformer] = []
        var autobotWins = 0
        var autobotLosses = 0
        var decepticonWins = 0
        var decepticonLosses = 0
        var countRounds = 0
        
        let numAutobots = autobots.count
        let numDecepticons = decepticons.count
        if numAutobots > numDecepticons {
            autobotSurvivors = Array(autobotCombatants.suffix(numAutobots - numDecepticons))
            autobotCombatants.removeLast(numAutobots - numDecepticons)
        } else if numAutobots < numDecepticons {
            decepticonSurvivors = Array(decepticonCombatants.suffix(numDecepticons - numAutobots))
            decepticonCombatants.removeLast(numDecepticons - numAutobots)
        }
        assert(autobotCombatants.count == decepticonCombatants.count)
        
        while autobotCombatants.isEmpty == false {
            countRounds += 1
            let autobot = autobotCombatants.removeFirst()
            let decepticon = decepticonCombatants.removeFirst()
            
            switch autobot.fight(against: decepticon) {
            case .win:
                autobotSurvivors.insert(autobot, at: autobotWins)
                autobotWins += 1
                decepticonLosses += 1
            case .loss:
                decepticonSurvivors.insert(decepticon, at: decepticonWins)
                decepticonWins += 1
                autobotLosses += 1
                
            case .tie:
                autobotLosses += 1
                decepticonLosses += 1
                
            case .destruction:
                return (result: .destruction, rounds: countRounds, survivingAutobots: [], survivingDecepticons: [])
            }
        }
        
        let battleResult: BattleResult
        if autobotLosses < decepticonLosses {
            battleResult = .autobotWin
        } else if autobotLosses > decepticonLosses {
            battleResult = .decepticonWin
        } else {
            battleResult = .tie
        }
        return (result: battleResult, rounds: countRounds, survivingAutobots: autobotSurvivors, survivingDecepticons: decepticonSurvivors)
    }
    
}
