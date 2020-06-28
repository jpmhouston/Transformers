//
//  ModelTests.swift
//  TransformersTests
//
//  Created by Pierre Houston on 2020-06-26.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import XCTest
@testable import Transformers

class ModelTests: XCTestCase {
    
    var autobot: Transformer!
    var decepticon: Transformer!
    
    override func setUp() {
        autobot = Transformer(id: "abc", name: "Dumbot", team: .autobots, rank: 1, strength: 2, intelligence: 3, speed: 4, endurance: 5, courage: 6, firepower: 11, skill: 8)
        decepticon = Transformer(name: "Dumbicon", team: .decepticons, rank: 1, strength: 3, intelligence: 3, speed: 3, endurance: 3, courage: 6, firepower: 6, skill: 6)
    }
    
    func testModelCreation() {
        XCTAssertEqual(autobot.id, "abc")
        XCTAssertNil(autobot.teamIcon)
        
        XCTAssertNil(decepticon.id)
        XCTAssertNil(decepticon.teamIcon)
    }
    
    func testModelInputAlias() {
        let x1 = TransformerInput(sourcedFrom: autobot, includingId: false)
        XCTAssertNil(x1.id)
        XCTAssertNil(x1.teamIcon)
        
        let x2 = TransformerInput(sourcedFrom: autobot)
        XCTAssertNotNil(x2.id)
        XCTAssertNil(x2.teamIcon)
        
        decepticon.teamIcon = "https://image.flaticon.com/icons/svg/3094/3094213.svg"
        let x3 = TransformerInput(sourcedFrom: decepticon)
        XCTAssertNil(x3.teamIcon)
        
        let x4 = TransformerInput(name: "Dummy", team: .autobots, rank: 1, strength: 1, intelligence: 1, speed: 1, endurance: 1, courage: 1, firepower: 1, skill: 1)
        XCTAssertNil(x4.id)
    }
    
    func testRating() {
        XCTAssertEqual(autobot.rating, 25)
        XCTAssertEqual(decepticon.rating, 18)
    }
    
    func testTeamName() {
        XCTAssertEqual(autobot.teamName, "Autobots")
        XCTAssertEqual(decepticon.teamName, "Decepticons")
        
        XCTAssertEqual(autobot.nameIncludingTeam, "Autobot Dumbot")
        XCTAssertEqual(decepticon.nameIncludingTeam, "Decepticon Dumbicon")
        
        // would also something under different locale if neccessary
        // see "localize" comments in Transformers.swift
    }
    
    func testSpecialness() {
        XCTAssertFalse(autobot.isSpecial)
        XCTAssertFalse(decepticon.isSpecial)
        
        var specialAutobotCopy = Transformer(copiedFrom: autobot)
        specialAutobotCopy.name = "Optimus Prime"
        XCTAssertTrue(specialAutobotCopy.isSpecial)
        
        var specialDecepticonCopy = Transformer(copiedFrom: decepticon)
        specialDecepticonCopy.name = "Predaking"
        XCTAssertTrue(specialDecepticonCopy.isSpecial)
    }
    
    func testMatchingName() {
        XCTAssertTrue(autobot.hasMatchingName(autobot.name))
        XCTAssertFalse(autobot.hasMatchingName("Banana"))
    }
    
    func testMatchingId() {
        XCTAssertTrue(autobot.hasMatchingId(autobot.id!))
        XCTAssertFalse(autobot.hasMatchingId("banana"))
    }
    
    func testSorting() {
        var autobotCopy = Transformer(copiedFrom: autobot, includingId: true)
        autobotCopy.name = "Dumbo"
        autobotCopy.rank = 2
        var decepticonCopy = Transformer(copiedFrom: decepticon, includingId: true)
        decepticonCopy.name = "Dumdum"
        decepticonCopy.rank = 2
        let list: [Transformer] = [autobot, decepticon, autobotCopy, decepticonCopy]
        
        let nameCompare = Transformer.orderWithCriteria([.name])
        let nameCompareDescending = Transformer.orderWithCriteria([.nameDescending])
        
        let nameSortAscending = list.sorted(by: nameCompare)
        XCTAssertEqual(nameSortAscending.map(\.name), ["Dumbicon", "Dumbo", "Dumbot", "Dumdum"])
        
        let nameSortDescending = list.sorted(by: nameCompareDescending)
        XCTAssertEqual(nameSortDescending.map(\.name), ["Dumdum", "Dumbot", "Dumbo", "Dumbicon"])
        
        let teamAndNameCompare = Transformer.orderWithCriteria([.team, .name])
        let teamAndNameSort = list.sorted(by: teamAndNameCompare)
        XCTAssertEqual(teamAndNameSort.map(\.name), ["Dumbo", "Dumbot", "Dumbicon", "Dumdum"])
        
        let rankAndNameCompare = Transformer.orderWithCriteria([.rankDescending, .name])
        let rankAndNameSort = list.sorted(by: rankAndNameCompare)
        XCTAssertEqual(rankAndNameSort.map(\.name), ["Dumbo", "Dumdum", "Dumbicon", "Dumbot"])
    }
    
    func testTeamCompare() {
        let teamCompare = Transformer.orderWithCriteria([.team])
        XCTAssertEqual(teamCompare(autobot, decepticon), true)
    }
    
    func testRatingCompare() {
        let ratingCompare = Transformer.orderWithCriteria([.rating])
        XCTAssertEqual(ratingCompare(decepticon, autobot), true)
    }
    
    func rankCompare() {
        var autobotRank2 = Transformer(copiedFrom: autobot)
        autobotRank2.name = "Dumbot2"
        autobotRank2.rank = 2
        
        let rankCompare = Transformer.orderWithCriteria([.rank])
        XCTAssertEqual(rankCompare(autobot, autobotRank2), true)
    }
    
    // maybe more tests of multicriteria comparisons?
    
}
