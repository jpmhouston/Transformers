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
        
        while autobotCombatants.isEmpty == false && decepticonCombatants.isEmpty == false {
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
                return BattleResult(finalOutcome: .destruction, roundResults: roundResults, startingAutobots: startingAutobots, startingDecepticons: startingDecepticons, autobotCasualties: startingAutobots, decepticonCasualties: startingDecepticons, autobotSurvivors: [], decepticonSurvivors: [])
            }
        }
        
        func buildFinalResult(withOutcome outcome: BattleOutcome) -> BattleResult {
            BattleResult(finalOutcome: outcome, roundResults: roundResults, startingAutobots: startingAutobots, startingDecepticons: startingDecepticons, autobotCasualties: autobotCasualties, decepticonCasualties: decepticonCasualties, autobotSurvivors: autobotSurvivors, decepticonSurvivors: decepticonSurvivors)
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

extension Transformer {
    
    // take string with newline-separated lines like these examples and build an array of Transformers
    // word 1 is A or D for the team, word 2 is rank number, word 3 is a list of seven comma-separated
    // (no spaces) stat numbers or just one number which is repeated for each stat, the rest is the name
    // A 1 5 Bob
    // D 2 4,4,4,4,4,4,4 Dave
    
    // note that the team icons used by this feature are the cartoon car and plane images grabbed from
    // a free icon site, the ones i use in the model unit tests.
    // i guess it would have been better to look at a log from server API calls and put in the urls for
    // those correct images, but i didn't want to hardcode those urls into the source code in any way
    
    static func customCombatants(forString input: String) -> [Transformer]? {
        guard input.count < 0x1000 else { return nil } // skip processing huge strings
        var output: [Transformer] = []
        for line in input.components(separatedBy: CharacterSet.newlines) {
            if line.isEmpty { continue } // skip blank lines, anything else unexpected => fail
            
            let words = line.components(separatedBy: CharacterSet.whitespaces)
            guard words.count >= 4 else { return nil }
            
            let team: Team
            switch words[0] {
            case "A": team = .autobots
            case "D": team = .decepticons
            default: return nil
            }
            
            guard let rank = Int(words[1]) else { return nil }
            
            let stats: [Int]
            let components = words[2].components(separatedBy: ",")
            switch components.count {
            case 1:
                guard let value = Int(components[0]) else { return nil }
                stats = Array(repeating: value, count: 7)
            case 7:
                stats = components.compactMap(Int.init)
                guard stats.count == 7 else { return nil }
            default: return nil
            }
            
            let name = words[3...].joined(separator: " ")
            
            let icon: String? = (team == .autobots ? "https://img.icons8.com/fluent/48/000000/car.png" : "https://img.icons8.com/color/48/000000/prop-plane.png")
            output.append(Transformer(id: nil, name: name, team: team, teamIcon: icon, rank: rank, strength: stats[0], intelligence: stats[1], speed: stats[2], endurance: stats[3], courage: stats[4], firepower: stats[5], skill: stats[6]))
        }
        return output.isEmpty ? nil : output
    }
    
}

/*
A 1 5 Lone Autobot

D 1 5 Lone Decepticon

A 1 5 Autotie
D 1 5 Deceptiecon

A 1 6 Autowin
D 1 5 Deceptilose

A 1 5 Loseobot
D 1 6 Deceptiwin

A 1 8 Optimus Prime
D 1 9 Deceptifail

A 1 9 Autofall
D 1 8 Predaking

A 1 5 Autotie One
A 2 6 Autotie Two
D 1 5 Deceptiecon
D 2 6 Deceptiecon Jr

A 1 5 Autotie Ay
A 2 6 Autotie Bee
A 1 3 Autotie Extra
D 1 5 Deceptiecon
D 2 6 Deceptieconrad

A 2 5 Autotie One
A 3 6 Autotie Two
D 2 5 Deceptiecon
D 3 6 Deceptiecon Jr
D 1 3 Deceptiextra
D 1 4 Deceptiebonus

A 1 6 Autosweep Ay
A 2 7 Autosweep Bee
A 3 8 Autosweep Ceecee
D 1 5 Dechokicon
D 2 6 Dechokiconway
D 3 7 Dechokiconnor

A 1 5 Autochoke One
A 2 6 Autochoke Two
D 1 6 Deceptisweep
D 2 7 Deceptisweep II

A 2 6 Autowin One
A 3 5 Autowin Two
A 4 8 Autowin Three
A 1 3 Autowin Extra
A 1 4 Autowin Bonus
D 2 5 Deceptilose
D 3 7 Deceptilose Jr
D 4 6 Deceptilose III

A 2 5 Losebot One
A 3 7 Losebot Two
A 4 6 Losebot Three
D 2 6 Deceptiwin
D 3 5 Deceptiwin II
D 4 7 Deceptiwin III
D 1 3 Deceptiwinnie
D 1 4 Deceptiwindex

A 2 5 Optimus Prime
A 3 6 Autodoomed
A 4 7 Autodoomed II
D 2 6 Predaking
D 3 7 Doomticon
D 4 6 Doomticontessa
D 1 4 Doomticonextra

A 1 5 Autobot With Long Name

D 1 5 Decepticon With Long Name

A 2 6 Autowin With Helalong Name
A 3 5 Autowin Two
A 4 8 Autowin Three
D 2 5 Deceptilose
D 3 7 Deceptilose Extended Moniker
D 4 6 Deceptilose III

A 2 6 Autolose
A 3 5 Autolost
A 4 8 Autowin Superextended Handle
D 2 5 Deceptilose
D 3 7 Deceptilose Junior Esquire
D 4 6 Deceptilose III
D 1 3 Deceptiloseanna

A 2 5 Losebot Bob
A 3 7 Losebot Adding Extra Verbiage
A 4 6 Losebot Lisa
A 1 3 Losebot Plus
A 1 4 Losebot Bingo
D 2 6 Deceptiwin
D 3 5 Deceptiwin II
D 4 7 Decepticon Winner The Third
 */
