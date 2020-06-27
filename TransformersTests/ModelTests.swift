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
        autobot = Transformer(id: "abc", name: "Dumbo", team: .autobots, rank: 1, strength: 2, intelligence: 3, speed: 4, endurance: 5, courage: 6, firepower: 11, skill: 8)
        decepticon = Transformer(name: "Dumdum", team: .decepticons, rank: 1, strength: 3, intelligence: 3, speed: 3, endurance: 3, courage: 6, firepower: 6, skill: 6)
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
        
        XCTAssertEqual(autobot.nameIncludingTeam, "Autobot Dumbo")
        XCTAssertEqual(decepticon.nameIncludingTeam, "Decepticon Dumdum")
        
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
        autobotCopy.name = "Dumbot"
        var decepticonCopy = Transformer(copiedFrom: decepticon, includingId: true)
        decepticonCopy.name = "Dumbicon"
        let list: [Transformer] = [autobot, decepticon, autobotCopy, decepticonCopy]
        
        let nameCompare = Transformer.comparisonWithCriteria([.name])
        let nameCompareDescending = Transformer.comparisonWithCriteria([.name], ascending: false)
        
        let nameSortAscending = list.sorted(by: nameCompare)
        XCTAssertEqual(nameSortAscending.map(\.name), ["Dumbicon", "Dumbo", "Dumbot", "Dumdum"])
        
        let nameSortDescending = list.sorted(by: nameCompareDescending)
        XCTAssertEqual(nameSortDescending.map(\.name), ["Dumdum", "Dumbot", "Dumbo", "Dumbicon"])
        
        let teamAndNameCompare = Transformer.comparisonWithCriteria([.team, .name])
        let teamAndNameCompareDescending = Transformer.comparisonWithCriteria([.team, .name], ascending: false)
        
        let teamAndNameSortAscending = list.sorted(by: teamAndNameCompare)
        XCTAssertEqual(teamAndNameSortAscending.map(\.name), ["Dumbo", "Dumbot", "Dumbicon", "Dumdum"])
        
        let teamAndNameSortDescending = list.sorted(by: teamAndNameCompareDescending)
        XCTAssertEqual(teamAndNameSortDescending.map(\.name), ["Dumdum", "Dumbicon", "Dumbot", "Dumbo"])
    }
    
    func testTeamCompare() {
        let teamCompare = Transformer.comparisonWithCriteria([.team])
        XCTAssertEqual(teamCompare(autobot, decepticon), true)
    }
    
    func testRatingCompare() {
        let ratingCompare = Transformer.comparisonWithCriteria([.rating])
        XCTAssertEqual(ratingCompare(decepticon, autobot), true)
    }
    
    func rankCompare() {
        var autobotRank2 = Transformer(copiedFrom: autobot)
        autobotRank2.name = "Dumbo2"
        autobotRank2.rank = 2
        
        let rankCompare = Transformer.comparisonWithCriteria([.rank])
        XCTAssertEqual(rankCompare(autobot, autobotRank2), true)
    }
    
    // maybe more tests of multicriteria comparisons?
    
}
