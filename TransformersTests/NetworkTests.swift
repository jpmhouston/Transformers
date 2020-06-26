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
                completion(.success(Transformer()))
            }
        }
        override func updateItem(_ data: TransformerInput, completion: @escaping (Result<Transformer, Error>) -> ()) {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                completion(.success(Transformer()))
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
    
    // todo: enable these tests when real networking finally connected
    
    func ztestLoadAuthorization() {
        let expectation = XCTestExpectation(description: "Receive allSpark authorization string")
        networkUtility.loadAuthorization() { result in
            XCTAssertNoThrow(try result.get())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func ztestLoadTransformerList() {
        let expectation = XCTestExpectation(description: "Receive current transformers list")
        networkUtility.loadList() { result in
            XCTAssertNoThrow(try result.get())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func ztestAddUpdateDeleteTransformer() {
        let testTransformerInput = TransformerInput() // todo: build from dummy data
        var resultTransformer: Transformer?
        let addExpectation = XCTestExpectation(description: "Send new test transformer")
        networkUtility.addItem(testTransformerInput) { result in
            do {
                resultTransformer = try result.get()
            } catch {
                XCTFail()
            }
            addExpectation.fulfill()
        }
        wait(for: [addExpectation], timeout: 1.0)
        XCTAssertNotNil(resultTransformer)
        
        let updateTransformerInput = TransformerInput() // todo: duplicate from resultTransformer! and modify
        let updateExpectation = XCTestExpectation(description: "Send test transformer update")
        networkUtility.updateItem(updateTransformerInput) { result in
            updateExpectation.fulfill()
        }
        wait(for: [updateExpectation], timeout: 1.0)
        
        let deleteExpectation = XCTestExpectation(description: "Send test transformer deletion")
        var returnedId: String?
        networkUtility.deleteItem("xyz") { result in // todo: pass resultTransformer.id instead of this string
            do {
                returnedId = try result.get()
            } catch {
                XCTFail()
            }
            XCTAssertEqual(returnedId, "xyz") //XCTAssertEqual(returnedId, resultTransformer.id)
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1.0)
    }
    
}
