//
//  NetworkUtility.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-25.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

protocol NetworkUtilityProtocol {
    func loadTransformerList(completion: @escaping (Error?) -> ())
    func addTransformer(_ data: TransformerInput, completion: @escaping (Error?) -> ())
    func updateTransformer(_ data: TransformerInput, completion: @escaping (Error?) -> ())
    func deleteTransformer(_ id: String, completion: @escaping (Error?) -> ())
}

protocol NetworkUtilityDelegate: AnyObject {
    func transformerListReceived(_ list: [Transformer])
    func transformerAdded(_ newTransformer: Transformer)
    func transformerUpdated(_ updatedTransformer: Transformer)
    func transformerDeleted(_ id: String)
}

class NetworkUtility: NetworkUtilityProtocol {
    
    enum NetworkError: Error, Equatable {
        case noAuthorization
        case authorizationUnsynchronized
        case urlError
    }
    
    enum AuthorizedState {
        case notLoading, loading, received, failed
    }
    
    weak var delegate: NetworkUtilityDelegate?
    
    var session: URLSession
    var authorizationQueue: DispatchQueue // vars below are updated only on this serial queueu
    var authorizedState: AuthorizedState = .notLoading
    var token: String?
    
    init() {
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config)
        
        let targetQueue = DispatchQueue.global(qos: .userInitiated)
        authorizationQueue = DispatchQueue(label: "NetworkUtility", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: targetQueue)
        
        // want to start transformer list download here, but without using react library or combine
        // it gets complicated to sync with call from view controller, so sadly for simplicity
        // wait until called by loadTransformerList
        //autoLoadTransformerList()
    }
    
    
    func loadTransformerList(completion: @escaping (Error?) -> ()) {
        func getList() {
            loadList() { result in
                do {
                    let list = try result.get()
                    self.delegate?.transformerListReceived(list)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
        
        if token == nil {
            synchronizedLoadAuthorization() { error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                    return
                }
                guard self.token != nil else {
                    DispatchQueue.main.async {
                        completion(NetworkError.noAuthorization)
                    }
                    return
                }
                getList()
            }
        } else {
            getList()
        }
    }
    
    func addTransformer(_ data: TransformerInput, completion: @escaping (Error?) -> ()) {
        addItem(data) { result in
            do {
                let transformer = try result.get()
                self.delegate?.transformerAdded(transformer)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    func updateTransformer(_ data: TransformerInput, completion: @escaping (Error?) -> ()) {
        updateItem(data) { result in
            do {
                let transformer = try result.get()
                self.delegate?.transformerUpdated(transformer)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    func deleteTransformer(_ id: String, completion: @escaping (Error?) -> ()) {
        deleteItem(id) { result in
            do {
                let id = try result.get()
                self.delegate?.transformerDeleted(id)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    
    // MARK: private functions
    
    func synchronizedLoadAuthorization(completion: @escaping (Error?) -> ()) {
        authorizationQueue.async {
            
            switch self.authorizedState {
            case .received:
                completion(nil) // received since this func called, complete immediately
                return
            case .loading:
                completion(NetworkError.authorizationUnsynchronized)
                return
            default:
                break
            }
            
            self.authorizedState = .loading
            self.loadAuthorization { result in
                self.authorizationQueue.async {
                    do {
                        self.token = try result.get()
                        self.authorizedState = .received
                        completion(nil)
                    } catch {
                        self.authorizedState = .failed
                        completion(error)
                    }
                }
            }
            
        }
    }
    
    var serverBase = "https://transformers-api.firebaseapp.com/"
    var authorize = "allSpark"
    var operations = "transformers"
    var authField = "Authorization"
    var authValuePrefix = "Bearer "
    var contentTypeField = "Content-Type"
    var contentTypeValue = "application/json"
    lazy var authorizationURL = URL(string: serverBase + authorize)
    lazy var operationsURL = URL(string: serverBase + operations)
    
    func loadAuthorization(completion: @escaping (Result<String, Error>) -> ()) {
        guard let url = authorizationURL else {
            completion(.failure(NetworkError.urlError))
            return
        }
        let request = URLRequest(url: url)
        _ = request
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            completion(.success("xyz"))
        }
    }
    
    func buildOperationRequest() throws -> URLRequest {
        guard let token = token else {
            throw NetworkError.noAuthorization
        }
        guard let url = operationsURL else {
            throw NetworkError.urlError
        }
        var request = URLRequest(url: url)
        request.addValue(authValuePrefix + token, forHTTPHeaderField: authField)
        request.addValue(contentTypeValue, forHTTPHeaderField: contentTypeField)
        return request
    }
    
    func loadList(completion: @escaping (Result<[Transformer], Error>) -> ()) {
        let request: URLRequest
        do {
            request = try buildOperationRequest()
        } catch {
            completion(.failure(error))
            return
        }
        _ = request
        
        // todo: finish this
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
            completion(.success([]))
        }
    }
    
    func addItem(_ data: TransformerInput, completion: @escaping (Result<Transformer, Error>) -> ()) {
        let request: URLRequest
        do {
            request = try buildOperationRequest()
        } catch {
            completion(.failure(error))
            return
        }
        _ = request
        
        // TODO: finish this
        // TODO: wrap in a background task to mostly ensure transaction completes if app backgrounded

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            var t = data
            t.id = "abcxyz"
            t.teamIcon = "https://image.flaticon.com/icons/svg/3094/3094213.svg"
            completion(.success(t))
        }
    }
    
    func updateItem(_ data: TransformerInput, completion: @escaping (Result<Transformer, Error>) -> ()) {
        let request: URLRequest
        do {
            request = try buildOperationRequest()
        } catch {
            completion(.failure(error))
            return
        }
        _ = request
        
        // TODO: finish this
        // TODO: wrap in a background task to mostly ensure transaction completes if app backgrounded
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            var t = data
            t.teamIcon = "https://image.flaticon.com/icons/svg/3094/3094213.svg"
            completion(.success(t))
        }
    }
    
    func deleteItem(_ id: String, completion: @escaping (Result<String, Error>) -> ()) {
        let request: URLRequest
        do {
            request = try buildOperationRequest()
        } catch {
            completion(.failure(error))
            return
        }
        _ = request
        
        // TODO: finish this
        // TODO: wrap in a background task to mostly ensure transaction completes if app backgrounded
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            completion(.success(id))
        }
    }
    
}
