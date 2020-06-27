//
//  DataController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-27.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

class DataController: NetworkUtilityDelegate {
    
    var runtimeStorage = Set<Transformer>()
    
    func transformerList(sortedBy: [Transformer.Sorting], ascending: Bool = true) -> [Transformer] {
        var sortCriteria = sortedBy
        if sortedBy.contains(.name) == false {
            sortCriteria.append(.name)
        }
        return runtimeStorage.sorted(by: Transformer.comparisonWithCriteria(sortCriteria, ascending: ascending))
    }
    
    func transformerNameUnique(_ name: String) -> Bool {
        return runtimeStorage.contains(where: { $0.hasMatchingName(name) }) == false
    }
    
    // MARK: NetworkUtilityDelegate conformance
    
    func transformerListReceived(_ data: [Transformer]) {
        runtimeStorage = Set(data)
    }
    
    func transformerAdded(_ newTransformer: Transformer) {
        // maybe this function should throw if another with matching name exists?
        // TODO: revisit validating name match during Add
        runtimeStorage.insert(newTransformer)
    }
    
    func transformerUpdated(_ updatedTransformer: Transformer) {
        guard let id = updatedTransformer.id else {
            assertionFailure("\(updatedTransformer.nameIncludingTeam) cannot be updated since id is nil")
            return // maybe this function should throw?
        }
        if let index = runtimeStorage.firstIndex(where: { $0.hasMatchingId(id) }) {
            runtimeStorage.remove(at: index)
        } else {
            assertionFailure("\(updatedTransformer.nameIncludingTeam) with id \(id) cannot be found to be updated")
            // correct to fallthrough to insert anyway? instead return or throw?
            // maybe ok to fallthrough and above assert should instead just be a warning?
            // TODO: revisit missing id match during Update
        }
        runtimeStorage.insert(updatedTransformer)
    }
    
    func transformerDeleted(_ id: String) {
        if let index = runtimeStorage.firstIndex(where: { $0.hasMatchingId(id) }) {
            runtimeStorage.remove(at: index)
        } else {
            assertionFailure("transformer with id \(id) cannot be found to be deleted")
            // maybe this function should throw?
            // TODO: revisit missing id match during Delete
        }
    }
    
}
