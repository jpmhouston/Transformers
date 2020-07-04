//
//  DataController.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-27.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

class DataController: NetworkUtilityDelegateProtocol {
    
    var runtimeStorage = Set<Transformer>()
    var benchedTransformersById = Set<String>() // cunning quick & dirty plan is to cache these in UserDefaults
    let defaults: UserDefaults
    #if DEBUG
    var cacheInUserDefaults = true
    #endif
    
    var editingTransformer: Transformer?
    var editingBenchedState: Bool?
    
    // MARK: -
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        readBenchedTransformerIds()
        setupRuntimeStorage()
    }
    
    func setupRuntimeStorage() {
        #if DEBUG
        var load: Bool
        load = cacheInUserDefaults // either set `cache..` to false, or `load` to false here at runtime, to ignore saved test data
        guard load, let encoded = defaults.value(forKey: "debugsave") as? Data else { return }
        let decoded = try! JSONDecoder().decode([Transformer].self, from: encoded)
        runtimeStorage = Set(decoded)
        #endif
    }
    
    func runtimeStorageUpdated() {
        #if DEBUG
        guard cacheInUserDefaults && runtimeStorage.isEmpty == false else { return }
        let encoded = try! JSONEncoder().encode(Array(runtimeStorage))
        defaults.set(encoded, forKey: "debugsave")
        defaults.synchronize()
        #endif
    }
    
    func transformerList(sortedBy: [Transformer.Sorting]) -> [Transformer] {
        var sortCriteria = sortedBy
        if sortedBy.contains(.name) == false {
            sortCriteria.append(.name)
        }
        return runtimeStorage.sorted(by: Transformer.orderWithCriteria(sortCriteria))
    }
    
    var isTransformerListEmpty: Bool {
        return runtimeStorage.isEmpty
    }
    
    var transformersForNextFight: [Transformer] {
        runtimeStorage.filter({ $0.id != nil && benchedTransformersById.contains($0.id!) == false })
    }
    
    func transformer(withId id: String) -> Transformer? {
        return runtimeStorage.first(where: { $0.id == id })
    }
    
    func transformerNameUnique(_ name: String) -> Bool {
        return runtimeStorage.contains(where: { $0.hasMatchingName(name) }) == false
    }
    
    func transformerNameUnique(_ name: String, otherThanId id: String) -> Bool {
        return runtimeStorage.contains(where: { $0.hasMatchingName(name) && $0.id != id }) == false
    }
    
    // MARK: benched transformers, stored locally out-of-band from other data
    
    func transformerBenchedState(withId id: String) -> Bool {
        return benchedTransformersById.contains(id)
    }
    
    func toggleBenchedState(forId id: String) {
        if benchedTransformersById.contains(id) {
            benchedTransformersById.remove(id)
        } else {
            benchedTransformersById.insert(id)
        }
        saveBenchedTransformerIds()
    }
    
    func setAllBenchedState(_ benched: Bool) {
        if benched {
            runtimeStorage.compactMap({ $0.id }).forEach { id in
                benchedTransformersById.insert(id)
            }
        } else {
            benchedTransformersById.removeAll()
        }
        saveBenchedTransformerIds()
    }
    
    func readBenchedTransformerIds() {
        guard let savedIds = defaults.value(forKey: "benchedids") as? [String] else { return }
        benchedTransformersById = Set(savedIds)
    }
    
    func saveBenchedTransformerIds() {
        defaults.set(Array(benchedTransformersById), forKey: "benchedids")
        defaults.synchronize()
    }
    
    // MARK: transformer being edited
    
    func startEditingTransformer(_ transformer: Transformer) {
        print("DataController.startEditedTransformer")
        editingTransformer = transformer
        editingBenchedState = false
    }
    
    func savingEditedTransformer() {
        print("DataController.savingEditedTransformer")
        guard let benched = editingBenchedState, let transformer = editingTransformer else { return }
        if let id = transformer.id {
            // can save the benched flag for this transformer because we have an id
            if benched {
                benchedTransformersById.insert(id)
                saveBenchedTransformerIds()
            }
            editingBenchedState = nil
        }
        // saving benched flag when no id? .. well this is where my cunning plan breaks down.
        // between when this is called and `transformerAdded` this transformer will have no id,
        // and we're not in control so we can't keep the flag captured in a closure.
        // to handle this will have to leak more of the mechanism to the flow controller,
        // or possibly complicate things with temporary local ids etc.
        // current bad plan is to keep the flag `editingBenchedState` until the next call to
        // `transformerAdded` which can then apply it to our local storage. easily broken
        // if app was made to save in the background then adding one then another quickly :^(
    }
    
    func finishSavingBenchedFlag(forId id: String) {
        print("DataController.finishSavingBenchedFlag id \(id) - lingering benched value hopefully not nil: \(String(describing: editingBenchedState))")
        guard let benched = editingBenchedState else { return }
        if benched {
            benchedTransformersById.insert(id)
            saveBenchedTransformerIds()
        }
        editingBenchedState = nil
    }
    
    func cancelSavingBenchedFlag() {
        editingBenchedState = nil
    }
    
    func dismissEditedTransformer() {
        editingTransformer = nil
        // don't touch editingBenchedState, it might be lingering until a save completes
        // see comment above about my cunning plan breaking down
    }
    
    // MARK: - editing callbacks
    // when i first made the immutable Transformers model i though i was making things easier,
    // but i forgot about this, all the combinations of creating a new state with 1 changed value.
    // could have made it easier with keypaths probably, didn't want to waste time experimenting
    
    func updateEditingTransformerName(_ newName: String) {
        guard let t = editingTransformer else { return }
        editingTransformer = Transformer(id: t.id, name: newName, team: t.team, teamIcon: t.teamIcon, rank: t.rank, strength: t.strength, intelligence: t.intelligence, speed: t.speed, endurance: t.endurance, courage: t.courage, firepower: t.firepower, skill: t.skill)
    }
    
    func updateEditingTransformerTeam(_ newTeam: Transformer.Team) {
        guard let t = editingTransformer else { return }
        editingTransformer = Transformer(id: t.id, name: t.name, team: newTeam, teamIcon: nil, rank: t.rank, strength: t.strength, intelligence: t.intelligence, speed: t.speed, endurance: t.endurance, courage: t.courage, firepower: t.firepower, skill: t.skill)
    }
    
    func updateEditingTransformerBenched(_ newIsBenched: Bool, forId id: String?) {
        editingBenchedState = newIsBenched
    }
    
    func updateEditingTransformerRank(_ newValue: Int) {
        guard let t = editingTransformer else { return }
        editingTransformer = Transformer(id: t.id, name: t.name, team: t.team, teamIcon: t.teamIcon, rank: newValue, strength: t.strength, intelligence: t.intelligence, speed: t.speed, endurance: t.endurance, courage: t.courage, firepower: t.firepower, skill: t.skill)
    }
    
    func updateEditingTransformerStrength(_ newValue: Int) {
        guard let t = editingTransformer else { return }
        editingTransformer = Transformer(id: t.id, name: t.name, team: t.team, teamIcon: t.teamIcon, rank: t.rank, strength: newValue, intelligence: t.intelligence, speed: t.speed, endurance: t.endurance, courage: t.courage, firepower: t.firepower, skill: t.skill)
    }
    
    func updateEditingTransformerIntelligence(_ newValue: Int) {
        guard let t = editingTransformer else { return }
        editingTransformer = Transformer(id: t.id, name: t.name, team: t.team, teamIcon: t.teamIcon, rank: t.rank, strength: t.strength, intelligence: newValue, speed: t.speed, endurance: t.endurance, courage: t.courage, firepower: t.firepower, skill: t.skill)
    }
    
    func updateEditingTransformerSpeed(_ newValue: Int) {
        guard let t = editingTransformer else { return }
        editingTransformer = Transformer(id: t.id, name: t.name, team: t.team, teamIcon: t.teamIcon, rank: t.rank, strength: t.strength, intelligence: t.intelligence, speed: newValue, endurance: t.endurance, courage: t.courage, firepower: t.firepower, skill: t.skill)
    }
    
    func updateEditingTransformerEndurance(_ newValue: Int) {
        guard let t = editingTransformer else { return }
        editingTransformer = Transformer(id: t.id, name: t.name, team: t.team, teamIcon: t.teamIcon, rank: t.rank, strength: t.strength, intelligence: t.intelligence, speed: t.speed, endurance: newValue, courage: t.courage, firepower: t.firepower, skill: t.skill)
    }
    
    func updateEditingTransformerCourage(_ newValue: Int) {
        guard let t = editingTransformer else { return }
        editingTransformer = Transformer(id: t.id, name: t.name, team: t.team, teamIcon: t.teamIcon, rank: t.rank, strength: t.strength, intelligence: t.intelligence, speed: t.speed, endurance: t.endurance, courage: newValue, firepower: t.firepower, skill: t.skill)
    }
    
    func updateEditingTransformerFirepower(_ newValue: Int) {
        guard let t = editingTransformer else { return }
        editingTransformer = Transformer(id: t.id, name: t.name, team: t.team, teamIcon: t.teamIcon, rank: t.rank, strength: t.strength, intelligence: t.intelligence, speed: t.speed, endurance: t.endurance, courage: t.courage, firepower: newValue, skill: t.skill)
    }
    
    func updateEditingTransformerSkill(_ newValue: Int) {
        guard let t = editingTransformer else { return }
        editingTransformer = Transformer(id: t.id, name: t.name, team: t.team, teamIcon: t.teamIcon, rank: t.rank, strength: t.strength, intelligence: t.intelligence, speed: t.speed, endurance: t.endurance, courage: t.courage, firepower: t.firepower, skill: newValue)
    }
    
    
    // MARK: - NetworkUtilityDelegate conformance
    
    func transformerListReceived(_ list: [Transformer]) {
        DispatchQueue.main.async {
            #if DEBUG
            if self.cacheInUserDefaults && list.isEmpty { return } // dont let empty list overwrite debug cache
            #endif
            self.runtimeStorage = Set(list)
            self.runtimeStorageUpdated()
        }
    }
    
    func transformerAdded(_ newTransformer: Transformer) {
        // maybe this function should throw if another with matching name exists??
        // A: no, it's reasonable to enforce name uniqueness elsewhere
        print("transformerAdded")
        DispatchQueue.main.async {
            print("transformerAdded - async main thread closure")
            self.runtimeStorage.insert(newTransformer)
            self.runtimeStorageUpdated()
            
            if let id = newTransformer.id {
                self.finishSavingBenchedFlag(forId: id)
            } else {
                self.cancelSavingBenchedFlag()
            }
        }
    }
    
    func transformerUpdated(_ updatedTransformer: Transformer) {
        guard let id = updatedTransformer.id else {
            assertionFailure("\(updatedTransformer.nameIncludingTeam) cannot be updated since id is nil")
            return // maybe this function should throw? in this case, probably. see also below
        }
        print("transformerUpdated")
        DispatchQueue.main.async {
            print("transformerUpdated - async main thread closure")
            if let index = self.runtimeStorage.firstIndex(where: { $0.hasMatchingId(id) }) {
                self.runtimeStorage.remove(at: index)
                self.runtimeStorageUpdated()
            } else {
                assertionFailure("\(updatedTransformer.nameIncludingTeam) with id \(id) cannot be found to be updated")
                // maybe correct to fallthrough to insert anyway? instead should it return or throw??
                // a non-toy data layer would need logging and sanity checking for data integrity
                // and partial failure, but even so such errors should probably stay here and
                // not complicate the code that called us
            }
            self.runtimeStorage.insert(updatedTransformer)
        }
    }
    
    func transformerDeleted(_ id: String) {
        print("transformerDeleted")
        DispatchQueue.main.async {
            print("transformerDeleted - async main thread closure")
            if let index = self.runtimeStorage.firstIndex(where: { $0.hasMatchingId(id) }) {
                self.runtimeStorage.remove(at: index)
                self.runtimeStorageUpdated()
            } else {
                assertionFailure("Transformer with id \(id) cannot be found to be deleted")
                // maybe this function should throw?? see comment above
            }
        }
    }
    
}
