//
//  TransformerEditorViewModel.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-29.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

struct TransformerEditorViewModel {
    let id: String?
    let name: String
    let isSpecial: Bool
    let team: Transformer.Team
    let teamIcon: String?
    let rating: Int
    let rank: Int
    let strength: Int
    let intelligence: Int
    let speed: Int
    let endurance: Int
    let firepower: Int
    let courage: Int
    let skill: Int
    let isBenched: Bool
    let allowDelete: Bool
    
    let dataController: DataController
    
    init(withDataController dataController: DataController) {
        guard let transformer = dataController.editingTransformer, let benchedState = dataController.editingBenchedState else {
            fatalError("Could not find data item being edited")
        }
        id = transformer.id
        name = transformer.name
        isSpecial = transformer.isSpecial
        team = transformer.team
        teamIcon = transformer.teamIcon
        rating = transformer.rating
        rank = transformer.rank
        strength = transformer.strength
        intelligence = transformer.intelligence
        speed = transformer.speed
        endurance = transformer.endurance
        firepower = transformer.firepower
        courage = transformer.courage
        skill = transformer.skill
        isBenched = benchedState
        allowDelete = transformer.id != nil
        
        self.dataController = dataController
    }
    
    enum ValidateResults { case valid, nameEmpty, nameNotUnique, rankOutOfBounds, valueOutOfBouds }
    
    func validate() -> ValidateResults {
        if name.isEmpty {
            return .nameEmpty
        } else if id == nil && dataController.transformerNameUnique(name) == false {
            return .nameNotUnique
        } else if id != nil && dataController.transformerNameUnique(name, otherThanId: id!) == false {
            return .nameNotUnique
        } else if rank <= 0 {
            return .rankOutOfBounds
        } else if strength < 0 || intelligence < 0 || speed < 0 || endurance < 0 || firepower < 0 || courage < 0 || skill < 0 {
            return .valueOutOfBouds
        }
        return .valid
    }
    
}
