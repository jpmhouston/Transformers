//
//  FightTests.swift
//  TransformersTests
//
//  Created by Pierre Houston on 2020-06-27.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import XCTest
@testable import Transformers

class FightTests: XCTestCase {

    var autobot: Transformer!
    var decepticon: Transformer!
    var optimusPrime: Transformer!
    var predaking: Transformer!
    
    override func setUp() {
        autobot = Transformer(id: "abc", name: "Dumbot", team: .autobots, rank: 1, strength: 2, intelligence: 3, speed: 4, endurance: 5, courage: 6, firepower: 11, skill: 8)
        decepticon = Transformer(id: "xyz", name: "Dumbicon", team: .decepticons, rank: 1, strength: 3, intelligence: 3, speed: 3, endurance: 3, courage: 6, firepower: 6, skill: 6)
        optimusPrime = Transformer(id: "aaa", name: "Optimus Prime", team: .autobots, rank: 10, strength: 3, intelligence: 3, speed: 3, endurance: 3, courage: 3, firepower: 3, skill: 3)
        predaking = Transformer(id: "zzz", name: "Predaking", team: .decepticons, rank: 10, strength: 3, intelligence: 3, speed: 3, endurance: 3, courage: 3, firepower: 3, skill: 3)
    }
    
    func testRatingFight() {
        let winResult = autobot.combat(against: decepticon)
        XCTAssertEqual(winResult, .win)
        
        let lossResult = decepticon.combat(against: autobot)
        XCTAssertEqual(lossResult, .loss)
    }

    func testRatingTie() {
        var duplicate = Transformer(copiedFrom: autobot)
        duplicate.team = .decepticons
        
        let tieResult = autobot.combat(against: duplicate)
        XCTAssertEqual(tieResult, .tie)
    }

    func testCourageFight() {
        decepticon.courage = autobot.courage + 4
        
        let lossResult = autobot.combat(against: decepticon)
        XCTAssertEqual(lossResult, .loss)
        
        let winResult = decepticon.combat(against: autobot)
        XCTAssertEqual(winResult, .win)
    }

    func testStrengthFight() {
        decepticon.strength = autobot.strength + 3
        
        let lossResult = autobot.combat(against: decepticon)
        XCTAssertEqual(lossResult, .loss)
        
        let winResult = decepticon.combat(against: autobot)
        XCTAssertEqual(winResult, .win)
    }

    func testSkillFight() {
        decepticon.skill = autobot.skill + 3
        
        let lossResult = autobot.combat(against: decepticon)
        XCTAssertEqual(lossResult, .loss)
        
        let winResult = decepticon.combat(against: autobot)
        XCTAssertEqual(winResult, .win)
    }

    func testAutomaticWin() {
        var primeCopy = Transformer(copiedFrom: optimusPrime)
        primeCopy.name = "Dummy Prime"
        var kingCopy = Transformer(copiedFrom: predaking)
        kingCopy.name = "Dummyking"
        
        let winResult = optimusPrime.combat(against: kingCopy)
        XCTAssertEqual(winResult, .win)
        
        let winResult2 = predaking.combat(against: primeCopy)
        XCTAssertEqual(winResult2, .win)
        
        let lossResult = kingCopy.combat(against: optimusPrime)
        XCTAssertEqual(lossResult, .loss)
        
        let lossResult2 = primeCopy.combat(against: predaking)
        XCTAssertEqual(lossResult2, .loss)
    }

    func testDestruction() {
        let nukeResult1 = optimusPrime.combat(against: predaking)
        XCTAssertEqual(nukeResult1, .destruction)
        
        let nukeResult2 = predaking.combat(against: optimusPrime)
        XCTAssertEqual(nukeResult2, .destruction)
    }
    
    func testBattles() {
        var autobotCopy = Transformer(copiedFrom: autobot, includingId: true)
        autobotCopy.name = "Dumbo"
        autobotCopy.rank = 2
        var decepticonCopy = Transformer(copiedFrom: decepticon, includingId: true)
        decepticonCopy.name = "Dumdum"
        decepticonCopy.rank = 2
        var autobotCopy2 = Transformer(copiedFrom: autobot, includingId: true)
        autobotCopy2.name = "Dumbo II"
        var decepticonCopy2 = Transformer(copiedFrom: decepticon, includingId: true)
        decepticonCopy2.name = "DumdumJunior"
        
        let combatants1: [Transformer] = [autobot, decepticon, autobotCopy, decepticonCopy, autobotCopy2]
        let results1 = Transformer.battle(betweenTransformers: combatants1)
        XCTAssertEqual(results1.finalOutcome, .autobotWin)
        XCTAssertEqual(results1.roundResults.count, 2)
        XCTAssertEqual(results1.autobotSurvivors.count, 3)
        XCTAssertEqual(results1.decepticonSurvivors.count, 0)
        
        let combatants2: [Transformer] = [autobot, decepticon, optimusPrime, decepticonCopy, decepticonCopy2]
        let results2 = Transformer.battle(betweenTransformers: combatants2)
        XCTAssertEqual(results2.finalOutcome, .autobotWin)
        XCTAssertEqual(results2.roundResults.count, 2)
        XCTAssertEqual(results2.autobotSurvivors.count, 2)
        XCTAssertEqual(results2.decepticonSurvivors.count, 1)
        
        // decepticonCopy is rank 2 goes against optimusPrime and loses not matter what, make the other 2 win
        decepticon.strength = 20
        decepticonCopy2.courage = 20
        let combatants3: [Transformer] = [autobot, decepticon, optimusPrime, decepticonCopy, autobotCopy2, decepticonCopy2]
        let results3 = Transformer.battle(betweenTransformers: combatants3)
        XCTAssertEqual(results3.finalOutcome, .decepticonWin)
        XCTAssertEqual(results3.roundResults.count, 3)
        XCTAssertEqual(results3.autobotSurvivors.count, 1)
        XCTAssertEqual(results3.decepticonSurvivors.count, 2)
    }
    
    func testTieBattle() {
        var autobotCopy = Transformer(copiedFrom: autobot, includingId: true)
        autobotCopy.name = "Dumbo"
        autobotCopy.rank = 2
        var decepticonCopy = Transformer(copiedFrom: decepticon, includingId: true)
        decepticonCopy.name = "Dumdum"
        decepticonCopy.rank = 2
        decepticonCopy.strength = 20 // allow this one to win
        let combatants: [Transformer] = [autobot, decepticon, autobotCopy, decepticonCopy]
        
        let result = Transformer.battle(betweenTransformers: combatants)
        XCTAssertEqual(result.finalOutcome, .tie)
        XCTAssertEqual(result.roundResults.count, 2)
    }
    
    func testNukedBattle() {
        let combatants1: [Transformer] = [autobot, decepticon, optimusPrime, predaking]
        let result = Transformer.battle(betweenTransformers: combatants1)
        XCTAssertEqual(result.finalOutcome, .destruction)
        XCTAssertEqual(result.roundResults.count, 1)
    }
    
}
