//
//  NetworkTests.swift
//  TransformersTests
//
//  Created by Pierre Houston on 2020-06-25.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import XCTest
@testable import Transformers

class NetworkAuthorizeAndLoadSynchronizationTests: XCTestCase {
    
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
                t.id = "banana"
                t.teamIcon = (t.team == .autobots ?
                    "https://img.icons8.com/fluent/48/000000/car.png" : "https://img.icons8.com/color/48/000000/prop-plane.png")
                completion(.success(t))
            }
        }
        override func updateItem(_ data: TransformerInput, completion: @escaping (Result<Transformer, Error>) -> ()) {
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                var t = data
                t.teamIcon = (t.team == .autobots ?
                    "https://img.icons8.com/fluent/48/000000/car.png" : "https://img.icons8.com/color/48/000000/prop-plane.png")
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
        let expectation = XCTestExpectation(description: "Synchronized loading of authorization then transformer list")
        networkUtility.loadTransformerList { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSimultaneousAuthorizingFailure() {
        let expectation = XCTestExpectation(description: "Synchronized loading of authorization then transformer list")
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
    var testName = "JPMH"
    
    enum NetworkTestError: Error { case unknown }
    
    override func setUp() {
        networkUtility = NetworkUtility()
    }
    
    func getAuthorization() -> Result<String,Error> {
        let authResult: Box<Result<String,Error>> = Box(.failure(NetworkTestError.unknown))
        let expectation = XCTestExpectation(description: "Receive allSpark authorization string")
        networkUtility.loadAuthorization() { result in
            self.networkUtility.token = try? result.get()
            authResult.value = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        return authResult.value
    }
    
    func addTestTransformer() -> Result<Transformer,Error> {
        let testTransformerInput = TransformerInput(name: testName, team: .autobots, rank: 1, strength: 1, intelligence: 1, speed: 1, endurance: 1, courage: 1, firepower: 1, skill: 1)
        let transformerResult: Box<Result<Transformer,Error>> = Box(.failure(NetworkTestError.unknown))
        let expectation = XCTestExpectation(description: "Send new test transformer")
        networkUtility.addItem(testTransformerInput) { result in
            transformerResult.value = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        return transformerResult.value
    }
    
    func loadListToFindTestTransformer() -> Result<Transformer?,Error> {
        let listResult: Box<Result<[Transformer],Error>> = Box(.failure(NetworkTestError.unknown))
        let expectation = XCTestExpectation(description: "Receive current transformers list")
        networkUtility.loadList() { result in
            listResult.value = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        let transformerResult: Result<Transformer?,Error> = listResult.value.map { list in return list.first(where: { $0.name == testName }) }
        return transformerResult
    }
    
    
    func testLoadAuthorization() {
        if let error = getAuthorization().failed() {
            XCTFail("Unable to get API authorization, error: \(error)")
        }
    }
    
    func testLoadTransformerList() {
        if let error = getAuthorization().failed() {
            XCTFail("Unable to get API authorization, error: \(error)")
            return
        }
        
        let listResult: Box<Result<[Transformer],Error>> = Box(.failure(NetworkTestError.unknown))
        let expectation = XCTestExpectation(description: "Receive current transformers list")
        networkUtility.loadList() { result in
            listResult.value = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        if let error = listResult.value.failed() {
            XCTFail("Call to loadList failed, error: \(error)")
        }
    }
    
    func testAddTransformerThenLoadList() {
        if let error = getAuthorization().failed() {
            XCTFail("Unable to get API authorization, error: \(error)")
            return
        }
        if let error = addTestTransformer().failed() {
            XCTFail("Call to addItem failed, error: \(error)")
            return
        }
        
        let listResult: Box<Result<[Transformer],Error>> = Box(.failure(NetworkTestError.unknown))
        let expectation = XCTestExpectation(description: "Receive updated transformers list")
        networkUtility.loadList() { result in
            listResult.value = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        if let error = listResult.value.failed() {
            XCTFail("Called to loadList failed, error: \(error)")
        }
    }
    
    func testUpdateTransformer() {
        if let error = getAuthorization().failed() {
            XCTFail("Unable to get API authorization, error: \(error)")
            return
        }
        
        var transformer: Transformer
        if let loadedTransformer = loadListToFindTestTransformer().succeeded(else: { XCTFail("Call to loadList failed, error: \($0)") }), loadedTransformer != nil {
            transformer = loadedTransformer!
        } else if let addedTransformer = addTestTransformer().succeeded(else: { XCTFail("Call to addItem failed, error: \($0)") }) {
            transformer = addedTransformer
        } else {
            return
        }
        
        let tweakRank = transformer.rank <= 1 ? (+1) : (Int.random(in: 0...1) * 2 - 1) // result of the random thing is either -1 or +1
        transformer.rank += tweakRank
        
        let updateTransformerInput = TransformerInput(sourcedFrom: transformer)
        let updateResult: Box<Result<Transformer,Error>> = Box(.failure(NetworkTestError.unknown))
        let expectation = XCTestExpectation(description: "Send test transformer update")
        networkUtility.updateItem(updateTransformerInput) { result in
            updateResult.value = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        if let error = updateResult.value.failed() {
            XCTFail("Call to updateItem failed, error: \(error)")
        } else if let updatedTransformer = updateResult.value.succeeded() {
            XCTAssertEqual(updatedTransformer.id, transformer.id)
        }
    }
    
    func testDeleteTransformer() {
        if let error = getAuthorization().failed() {
            XCTFail("Unable to get API authorization, error: \(error)")
            return
        }
        
        var transformer: Transformer
        if let loadedTransformer = loadListToFindTestTransformer().succeeded(else: { XCTFail("Call to loadList failed, error: \($0)") }), loadedTransformer != nil {
            transformer = loadedTransformer!
        } else if let addedTransformer = addTestTransformer().succeeded(else: { XCTFail("Call to addItem failed, error: \($0)") }) {
            transformer = addedTransformer
        } else {
            return
        }
        guard let id = transformer.id else {
            XCTFail("The id is nil for the found transformer, cannot delete")
            return
        }
        
        let idResult: Box<Result<String,Error>> = Box(.failure(NetworkTestError.unknown))
        let expectation = XCTestExpectation(description: "Send test transformer deletion")
        networkUtility.deleteItem(id) { result in
            idResult.value = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        if let error = idResult.value.failed() {
            XCTFail("Call to deleteItem failed, error: \(error)")
        } else if let returnedId = idResult.value.succeeded() {
            XCTAssertEqual(returnedId, id)
        }
    }
    
}

// MARK: -

// wrote this to simplify the gobs of Result inspecting code above. ok, well the `else`
// closure parameter ends up a little complex whenever its used, but it's not too bad, is it?
// https://gist.github.com/jpmhouston/c2d827cf469e23c09bda7a901710313f
extension Result {
    func failed(else handleSuccess: ((Success) -> Void)? = nil) -> Failure? {
        switch self {
        case .success(let value):
            handleSuccess?(value)
            return nil
        case .failure(let error):
            return error
        }
    }
    
    func succeeded(else handleFailure: ((Failure) -> Void)? = nil) -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            handleFailure?(error)
            return nil
        }
    }
}

// wanted to violate read-only value type captures in code above, borrowed this from
// github.com/robrix/Box and stripped out all but its MutableBox implementation
public protocol BoxType {
    associatedtype Value
    init(_ value: Value)
    var value: Value { get set }
}
class Box<T>: BoxType {
    required init(_ value: T) { self.value = value }
    public var value: T
}
