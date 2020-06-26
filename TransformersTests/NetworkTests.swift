//
//  NetworkTests.swift
//  TransformersTests
//
//  Created by Pierre Houston on 2020-06-25.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import XCTest
@testable import Transformers

class NetworkAuthorizationTests: XCTestCase {
    
    // subclass NetworkUtility to override with mock implementations of
    // loadAuthorization, loadList, addItem, updateItem, deleteItem
    
    class MockedNetworkUtility: NetworkUtility {
        override func loadAuthorization(completion: @escaping (Result<String, Error>) -> ()) {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                completion(.success("xyz"))
            }
        }
        override func loadList(completion: @escaping (Result<[Transformer], Error>) -> ()) {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                completion(.success([]))
            }
        }
        // if we tested against adding, updating, deleting, then would need these overrides too
        override func addItem(_ data: TransformerInput, completion: @escaping (Result<Transformer, Error>) -> ()) {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                var t = data
                t.id = "abcxyz"
                t.teamIcon = "https://image.flaticon.com/icons/svg/3094/3094213.svg"
                completion(.success(t))
            }
        }
        override func updateItem(_ data: TransformerInput, completion: @escaping (Result<Transformer, Error>) -> ()) {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                var t = data
                t.teamIcon = "https://image.flaticon.com/icons/svg/3094/3094213.svg"
                completion(.success(t))
            }
        }
        override func deleteItem(_ id: String, completion: @escaping (Result<String, Error>) -> ()) {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                completion(.success(id))
            }
        }
    }
    
    var networkUtility: MockedNetworkUtility!
    
    override func setUp() {
        networkUtility = MockedNetworkUtility()
    }
    
    func testAuthorizingLoading() {
        let expectation = XCTestExpectation(description: "Synchronized loading of authorization then trandformer list")
        networkUtility.loadTransformerList { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSimultaneousAuthorizingFailure() {
        let expectation = XCTestExpectation(description: "Synchronized loading of authorization then trandformer list")
        networkUtility.loadTransformerList { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2)) {
            self.networkUtility.loadTransformerList { error in
                XCTAssertNotNil(error)
                guard let networkError = error! as? NetworkUtility.NetworkError else {
                    XCTFail("Some other error when expected .authorizationUnsynchronized, \(error!)")
                    return
                }
                XCTAssert(networkError == NetworkUtility.NetworkError.authorizationUnsynchronized)
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
}

class NetworkConnectionTests: XCTestCase {
    
    var networkUtility: NetworkUtility!
    
    override func setUp() {
        networkUtility = NetworkUtility()
    }
    
    func testLoadAuthorization() {
        let expectation = XCTestExpectation(description: "Receive allSpark authorization string")
        networkUtility.loadAuthorization() { result in
            // would use XCTAssertNoThrow here but it causes this closure to be throwing & thus error "Invalid conversion from throwing function"
            do {
                let _ = try result.get()
            } catch {
                XCTFail("loadAuthorization failed with error \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func getAuthorization() -> Bool {
        var ok = true
        let expectation = XCTestExpectation(description: "Receive allSpark authorization string")
        networkUtility.loadAuthorization() { result in
            // would use XCTAssertNoThrow here but it causes this closure to be throwing & thus error "Invalid conversion from throwing function"
            do {
                self.networkUtility.token = try result.get()
            } catch {
                ok = false
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return ok
    }
    
    func testLoadTransformerList() {
        guard getAuthorization() else {
            XCTFail("Unabled to get API authorization")
            return
        }
        
        let expectation = XCTestExpectation(description: "Receive current transformers list")
        networkUtility.loadList() { result in
            // would use XCTAssertNoThrow here but it causes this closure to be throwing & thus error "Invalid conversion from throwing function"
            do {
                let _ = try result.get()
            } catch {
                XCTFail("loadList failed with error \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddUpdateDeleteTransformer() {
        guard getAuthorization() else {
            XCTFail("Unabled to get API authorization")
            return
        }
        
        let testTransformerInput = TransformerInput(name: "Dummy", team: .autobots, rank: 1, strength: 1, intellegence: 1, speek: 1, endurance: 1, courage: 1, firepower: 1, skill: 1)
        var resultTransformer: Transformer?
        let addExpectation = XCTestExpectation(description: "Send new test transformer")
        networkUtility.addItem(testTransformerInput) { result in
            do {
                resultTransformer = try result.get()
            } catch {
                XCTFail("addItem failed with error \(error)")
            }
            addExpectation.fulfill()
        }
        wait(for: [addExpectation], timeout: 1.0)
        XCTAssertNotNil(resultTransformer)
        
        guard resultTransformer != nil else { return }
        
        let updateTransformerInput = TransformerInput(from: resultTransformer!)
        let updateExpectation = XCTestExpectation(description: "Send test transformer update")
        networkUtility.updateItem(updateTransformerInput) { result in
            do {
                _ = try result.get()
            } catch {
                XCTFail("updateItem failed with error \(error)")
            }
            updateExpectation.fulfill()
        }
        wait(for: [updateExpectation], timeout: 1.0)
        
        guard let transformerId = resultTransformer?.id else { return }
        
        let deleteExpectation = XCTestExpectation(description: "Send test transformer deletion")
        var returnedId: String?
        networkUtility.deleteItem(transformerId) { result in
            do {
                returnedId = try result.get()
            } catch {
                XCTFail("deleteItem failed with error \(error)")
            }
            XCTAssertEqual(returnedId, transformerId)
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1.0)
    }
    
}
