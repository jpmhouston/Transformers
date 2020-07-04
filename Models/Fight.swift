//
//  Fight.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-26.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

extension Transformer {
    
    // combat is single transformer vs transformer, no attention is payed to team
    // (so could be used for sparring amongst own team i guess) and produces just an outcome enum
    
    enum FightOutcome {
        case win, loss, tie, destruction
    }
    
    func combat(against opponent: Transformer) -> FightOutcome {
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
    
    // a battle is very much team vs team with the unsorted transformers provided divided beforehand
    // and produces a struct containing the results, including a breakdown round by round
    
    enum BattleOutcome {
        case autobotWin, decepticonWin, tie, destruction
    }
    
    struct RoundResult {
        let autobot: Transformer
        let decepticon: Transformer
        let outcome: BattleOutcome
    }
    
    struct BattleResult {
        let finalOutcome: BattleOutcome?
        let roundResults: [RoundResult]
        let startingAutobots: [Transformer]
        let startingDecepticons: [Transformer]
        let autobotCasualties: [Transformer]
        let decepticonCasualties: [Transformer]
        let autobotSurvivors: [Transformer]
        let decepticonSurvivors: [Transformer]
    }
    
    // `battle(betweenAutobots:andDecepticons:) throws if an autobot is found amongst the decepticons
    // battle team, or vice-versa. expect however it's `battle(betweenTransformers:)` function
    // instead that will actually used, and it does the splitting into teams itself which is
    // assumed to always work (hance its confident use of `try!`).
    // probably `battle(betweenAutobots:andDecepticons:)` should be private and we shouldn't even
    // bother testing for these error conditions
    enum BattleError: Error {
        case traitorAutobot, traitorDecepticon
    }
    
    static func battle(betweenTransformers transformers: [Transformer]) -> BattleResult {
        let autobots = transformers.filter { $0.team == .autobots }
        let decepticons = transformers.filter { $0.team == .decepticons }
        return try! battle(betweenAutobots: autobots, andDecepticons: decepticons)
    }
    
    static func battle(betweenAutobots autobots: [Transformer], andDecepticons decepticons: [Transformer]) throws -> BattleResult {
        guard autobots.contains(where: { $0.team == .decepticons }) == false else {
            throw BattleError.traitorDecepticon
        }
        guard decepticons.contains(where: { $0.team == .autobots }) == false else {
            throw BattleError.traitorAutobot
        }
        
        let rankSort = Transformer.orderWithCriteria([.rankDescending, .name])
        var startingAutobots: [Transformer] = autobots.sorted(by: rankSort)
        var startingDecepticons: [Transformer] = decepticons.sorted(by: rankSort)
        
        guard (startingAutobots.isEmpty || startingDecepticons.isEmpty) == false else {
            return BattleResult(finalOutcome: nil, roundResults: [], startingAutobots: startingAutobots, startingDecepticons: startingDecepticons, autobotCasualties: [], decepticonCasualties: [], autobotSurvivors: startingAutobots, decepticonSurvivors: startingDecepticons)
        }
        
        var autobotCombatants = startingAutobots
        var decepticonCombatants = startingDecepticons
        var autobotSurvivors: [Transformer] = []
        var decepticonSurvivors: [Transformer] = []
        var autobotCasualties: [Transformer] = []
        var decepticonCasualties: [Transformer] = []
        var autobotWinCount = 0
        var decepticonWinCount = 0
        var roundResults: [RoundResult] = []
        
        func buildFinalResult(withOutcome outcome: BattleOutcome) -> BattleResult {
            BattleResult(finalOutcome: outcome, roundResults: roundResults, startingAutobots: startingAutobots, startingDecepticons: startingDecepticons, autobotCasualties: autobotCasualties, decepticonCasualties: decepticonCasualties, autobotSurvivors: autobotSurvivors, decepticonSurvivors: decepticonSurvivors)
        }
        func buildDestructionResult() -> BattleResult {
            BattleResult(finalOutcome: .destruction, roundResults: roundResults, startingAutobots: startingAutobots, startingDecepticons: startingDecepticons, autobotCasualties: startingAutobots, decepticonCasualties: startingDecepticons, autobotSurvivors: [], decepticonSurvivors: [])
        }
        
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
            let autobot = autobotCombatants.removeFirst()
            let decepticon = decepticonCombatants.removeFirst()
            
            let outcome: BattleOutcome
            
            switch autobot.combat(against: decepticon) {
            case .win:
                outcome = .autobotWin
                autobotSurvivors.insert(autobot, at: autobotWinCount)
                decepticonCasualties.append(decepticon)
                autobotWinCount += 1
                
            case .loss:
                outcome = .decepticonWin
                decepticonSurvivors.insert(decepticon, at: decepticonWinCount)
                autobotCasualties.append(autobot)
                decepticonWinCount += 1
                
            case .tie:
                outcome = .tie
                autobotCasualties.append(autobot)
                decepticonCasualties.append(decepticon)
                
            case .destruction:
                outcome = .destruction
                // don't bother accounting, all are wiped out
            }
            
            roundResults.append(RoundResult(autobot: autobot, decepticon: decepticon, outcome: outcome))
            
            if outcome == .destruction {
                return buildDestructionResult()
            }
        }
        
        let autobotLosses = autobotCasualties.count
        let decepticonLosses = decepticonCasualties.count
        
        if autobotLosses < decepticonLosses || startingDecepticons.isEmpty{
            return buildFinalResult(withOutcome: .autobotWin)
        } else if autobotLosses > decepticonLosses || startingAutobots.isEmpty{
            return buildFinalResult(withOutcome: .decepticonWin)
        } else {
            return buildFinalResult(withOutcome: .tie)
        }
    }
    
}
