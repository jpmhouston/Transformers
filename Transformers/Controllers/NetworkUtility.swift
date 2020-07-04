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

protocol NetworkUtilityDelegateProtocol: AnyObject {
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
        case badResponseCode(Int)
        case badResponseData
        case authorizationEmpty
        case encodingError
    }
    
    enum AuthorizedState {
        case notLoading, loading, received, failed
    }
    
    weak var delegate: NetworkUtilityDelegateProtocol?
    
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
    
    struct TransformerResponse: Codable {
        var transformers: [Transformer]
    }
    
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
    
    func decode<T>(from data: Data) -> T? where T: Decodable {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Failed to decode to a \(T.self): \(error)")
            return nil
        }
    }
    
    func encode<T>(from value: T) -> Data? where T: Encodable {
        do {
            return try encoder.encode(value)
        } catch {
            print("Failed to encode a \(type(of: value)): \(error)")
            return nil
        }
    }
    
    func buildOperationRequest(withPathComponent pathComponent: String? = nil) throws -> URLRequest {
        guard let token = token else {
            throw NetworkError.noAuthorization
        }
        guard var url = operationsURL else {
            throw NetworkError.urlError
        }
        if let component = pathComponent {
            url = url.appendingPathComponent(component)
        }
        var request = URLRequest(url: url)
        request.addValue(authValuePrefix + token, forHTTPHeaderField: authField)
        request.addValue(contentTypeValue, forHTTPHeaderField: contentTypeField)
        return request
    }
    
    
    func loadAuthorization(completion: @escaping (Result<String, Error>) -> ()) {
        guard let url = authorizationURL else {
            completion(.failure(NetworkError.urlError))
            return
        }
        let request = URLRequest(url: url)
        
        // TODO: wrap in a background task to mostly ensure transaction completes if app backgrounded
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 200 {
                completion(.failure(NetworkError.badResponseCode(statusCode)))
            } else if self == nil {
                return // or call completion also even if self is gone & app is shutting down?
                
            } else if let data = data, let authorizationKey = String(data: data, encoding: .utf8) {
                completion(.success(authorizationKey))
                
            } else {
                completion(.failure(NetworkError.badResponseData))
            }
        }
        task.resume()
    }
    
    func loadList(completion: @escaping (Result<[Transformer], Error>) -> ()) {
        let request: URLRequest
        do {
            request = try buildOperationRequest()
        } catch {
            completion(.failure(error))
            return
        }
        
        // TODO: wrap in a background task to mostly ensure transaction completes if app backgrounded
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 200 {
                completion(.failure(NetworkError.badResponseCode(statusCode)))
            } else if self == nil {
                return // or call completion also even if self is gone & app is shutting down?
                
            } else if let data = data, let decoded: TransformerResponse = self!.decode(from: data) {
                completion(.success(decoded.transformers))
                
            } else {
                completion(.failure(NetworkError.badResponseData))
            }
        }
        task.resume()
    }
    
    func addItem(_ data: TransformerInput, completion: @escaping (Result<Transformer, Error>) -> ()) {
        var request: URLRequest
        do {
            request = try buildOperationRequest()
        } catch {
            completion(.failure(error))
            return
        }
        
        guard let encoded = encode(from: data) else {
            completion(.failure(NetworkError.encodingError))
            return
        }
        request.httpMethod = "POST"
        request.httpBody = encoded
        
        // TODO: wrap in a background task to mostly ensure transaction completes if app backgrounded
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 201 {
                completion(.failure(NetworkError.badResponseCode(statusCode)))
            } else if self == nil {
                return // or call completion also even if self is gone & app is shutting down?
                
            } else if let data = data, let decoded: Transformer = self?.decode(from: data) {
                completion(.success(decoded))
                
            } else {
                completion(.failure(NetworkError.badResponseData))
            }
        }
        task.resume()
    }
    
    func updateItem(_ data: TransformerInput, completion: @escaping (Result<Transformer, Error>) -> ()) {
        var request: URLRequest
        do {
            request = try buildOperationRequest()
        } catch {
            completion(.failure(error))
            return
        }
        
        guard let encoded = encode(from: data) else {
            completion(.failure(NetworkError.encodingError))
            return
        }
        request.httpMethod = "PUT"
        request.httpBody = encoded
        
        // TODO: wrap in a background task to mostly ensure transaction completes if app backgrounded
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 200 {
                completion(.failure(NetworkError.badResponseCode(statusCode)))
            } else if self == nil {
                return // or call completion also even if self is gone & app is shutting down?
                
            } else if let data = data, let decoded: Transformer = self?.decode(from: data) {
                completion(.success(decoded))
                
            } else {
                completion(.failure(NetworkError.badResponseData))
            }
        }
        task.resume()
    }
    
    func deleteItem(_ id: String, completion: @escaping (Result<String, Error>) -> ()) {
        var request: URLRequest
        do {
            request = try buildOperationRequest(withPathComponent: id)
        } catch {
            completion(.failure(error))
            return
        }
        
        request.httpMethod = "DELETE"
        
        // TODO: wrap in a background task to mostly ensure transaction completes if app backgrounded
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 204 {
                completion(.failure(NetworkError.badResponseCode(statusCode)))
            } else if self == nil {
                return // or call completion also even if self is gone & app is shutting down?
                
            } else {
                completion(.success(id)) // return the id we were passed, currently don't decode & return the list response
            }
        }
        task.resume()
    }
    
}
