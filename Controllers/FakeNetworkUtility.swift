//
//  FakeNetworkUtility.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-07-03.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

class FakeNetworkUtility: NetworkUtility {
    
    // this is a variation on NetworkUtility which loads from & saves to UserDefaults
    // instead of the server API
    
    lazy var defaults: UserDefaults = UserDefaults.standard
    let listKey = "debugsave"
    
    func readFromUserDefaults() -> [Transformer] {
        guard let encoded = defaults.value(forKey: listKey) as? Data else {
            return []
        }
        guard let decoded = try? JSONDecoder().decode([Transformer].self, from: encoded) else {
            print("Could not decode userdefaults transformerlist")
            //defaults.set(nil, forKey: listKey) // delete corrupted data?
            return []
        }
        return decoded
    }
    
    func writeToUserDefaults(_ list: [Transformer]) {
        let encoded = try! JSONEncoder().encode(Array(list))
        defaults.set(encoded, forKey: listKey)
        defaults.synchronize()
    }
    
    // MARK: -
    
    override func loadAuthorization(completion: @escaping (Result<String, Error>) -> ()) {
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            completion(.success("banana"))
        }
    }
    
    override func loadList(completion: @escaping (Result<[Transformer], Error>) -> ()) {
        let list = readFromUserDefaults()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
            completion(.success(list))
        }
    }
    
    override func addItem(_ data: TransformerInput, completion: @escaping (Result<Transformer, Error>) -> ()) {
        var t = Transformer(copiedFrom: data, replacingId: String(arc4random()))
        t.teamIcon = (t.team == .autobots ?
            "https://img.icons8.com/fluent/48/000000/car.png" : "https://img.icons8.com/color/48/000000/prop-plane.png")
        
        var list = readFromUserDefaults()
        list.append(t)
        writeToUserDefaults(list)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            completion(.success(t))
        }
    }
    
    override func updateItem(_ data: TransformerInput, completion: @escaping (Result<Transformer, Error>) -> ()) {
        var t = Transformer(copiedFrom: data)
        t.teamIcon = (t.team == .autobots ?
            "https://img.icons8.com/fluent/48/000000/car.png" : "https://img.icons8.com/color/48/000000/prop-plane.png")
        
        var list = readFromUserDefaults()
        if let index = list.firstIndex(where: { $0.id == t.id }) {
            list.remove(at: index)
        } else {
            print("Couldn't find transformer with id \"\(t.id ?? "")\" in userdefaults transformerlist")
        }
        list.append(t)
        writeToUserDefaults(list)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            completion(.success(t))
        }
    }
    
    override func deleteItem(_ id: String, completion: @escaping (Result<String, Error>) -> ()) {
        var list = readFromUserDefaults()
        if let index = list.firstIndex(where: { $0.id == id }) {
            list.remove(at: index)
            writeToUserDefaults(list)
        } else {
            print("Couldn't find transformer with id \"\(id)\" in userdefaults transformerlist")
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            completion(.success(id))
        }
    }
    
}
