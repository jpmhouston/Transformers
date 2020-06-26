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
    
    var t1: Transformer!
    var t2: Transformer!
    
    override func setUp() {
        t1 = Transformer(id: "abc", name: "Dumbo", team: .autobots, rank: 1, strength: 1, intellegence: 1, speek: 1, endurance: 1, courage: 1, firepower: 1, skill: 1)
        t2 = Transformer(name: "Dumdum", team: .decepticons, rank: 1, strength: 1, intellegence: 1, speek: 1, endurance: 1, courage: 1, firepower: 1, skill: 1)
    }
    
    func testModelCreation() {
        XCTAssertEqual(t1.id, "abc")
        XCTAssertNil(t1.teamIcon)
        
        XCTAssertNil(t2.id)
        XCTAssertNil(t2.teamIcon)
    }
    
    func testModelInputAlias() {
        let x1 = TransformerInput(from: t1, excludingId: true)
        XCTAssertNil(x1.id)
        XCTAssertNil(x1.teamIcon)
        
        let x2 = TransformerInput(from: t1)
        XCTAssertNotNil(x2.id)
        XCTAssertNil(x2.teamIcon)
        
        t2.teamIcon = "https://image.flaticon.com/icons/svg/3094/3094213.svg"
        let x3 = TransformerInput(from: t2)
        XCTAssertNil(x3.teamIcon)
        
        let x4 = TransformerInput(name: "Dummy", team: .autobots, rank: 1, strength: 1, intellegence: 1, speek: 1, endurance: 1, courage: 1, firepower: 1, skill: 1)
        XCTAssertNil(x4.id)
    }
    
}
