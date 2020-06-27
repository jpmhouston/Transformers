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
        autobot = Transformer(id: "abc", name: "Dumbo", team: .autobots, rank: 1, strength: 2, intelligence: 3, speed: 4, endurance: 5, courage: 6, firepower: 11, skill: 8)
        decepticon = Transformer(id: "xyz", name: "Dumdum", team: .decepticons, rank: 1, strength: 3, intelligence: 3, speed: 3, endurance: 3, courage: 6, firepower: 6, skill: 6)
        optimusPrime = Transformer(id: "aaa", name: "Optimus Prime", team: .autobots, rank: 10, strength: 3, intelligence: 3, speed: 3, endurance: 3, courage: 3, firepower: 3, skill: 3)
        predaking = Transformer(id: "zzz", name: "Predaking", team: .decepticons, rank: 10, strength: 3, intelligence: 3, speed: 3, endurance: 3, courage: 3, firepower: 3, skill: 3)
    }
    
    func testRatingFight() {
        let winResult = autobot.fight(against: decepticon)
        XCTAssertEqual(winResult, .win)
        
        let lossResult = decepticon.fight(against: autobot)
        XCTAssertEqual(lossResult, .loss)
    }

    func testRatingTie() {
        var duplicate = Transformer(copiedFrom: autobot)
        duplicate.team = .decepticons
        
        let tieResult = autobot.fight(against: duplicate)
        XCTAssertEqual(tieResult, .tie)
    }

    func testCourageFight() {
        decepticon.courage = autobot.courage + 4
        
        let lossResult = autobot.fight(against: decepticon)
        XCTAssertEqual(lossResult, .loss)
        
        let winResult = decepticon.fight(against: autobot)
        XCTAssertEqual(winResult, .win)
    }

    func testStrengthFight() {
        decepticon.strength = autobot.strength + 3
        
        let lossResult = autobot.fight(against: decepticon)
        XCTAssertEqual(lossResult, .loss)
        
        let winResult = decepticon.fight(against: autobot)
        XCTAssertEqual(winResult, .win)
    }

    func testSkillFight() {
        decepticon.skill = autobot.skill + 3
        
        let lossResult = autobot.fight(against: decepticon)
        XCTAssertEqual(lossResult, .loss)
        
        let winResult = decepticon.fight(against: autobot)
        XCTAssertEqual(winResult, .win)
    }

    func testAutomaticWin() {
        var primeCopy = Transformer(copiedFrom: optimusPrime)
        primeCopy.name = "Dummy Prime"
        var kingCopy = Transformer(copiedFrom: predaking)
        kingCopy.name = "Dummyking"
        
        let winResult = optimusPrime.fight(against: kingCopy)
        XCTAssertEqual(winResult, .win)
        
        let winResult2 = predaking.fight(against: primeCopy)
        XCTAssertEqual(winResult2, .win)
        
        let lossResult = kingCopy.fight(against: optimusPrime)
        XCTAssertEqual(lossResult, .loss)
        
        let lossResult2 = primeCopy.fight(against: predaking)
        XCTAssertEqual(lossResult2, .loss)
    }

    func testDestruction() {
        let nukeResult1 = optimusPrime.fight(against: predaking)
        XCTAssertEqual(nukeResult1, .destruction)
        
        let nukeResult2 = predaking.fight(against: optimusPrime)
        XCTAssertEqual(nukeResult2, .destruction)
    }
    
}
