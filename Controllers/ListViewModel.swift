//
//  ListViewModel.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-29.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

struct ListViewModel {
    struct TransformerItem {
        let id: String
        let name: String
        let isSpecial: Bool
        let teamIcon: String?
        let rating: Int
        let rank: Int
        let isBenched: Bool
    }
    let transformers: [TransformerItem]
    
    init(withDataController dataController: DataController) {
        let transformerList = dataController.transformerList(sortedBy: [.name])
        transformers = transformerList.compactMap { transformer in
            guard let id = transformer.id else { return nil }
            return TransformerItem(id: id,
                                   name: transformer.name,
                                   isSpecial: transformer.isSpecial,
                                   teamIcon: transformer.teamIcon,
                                   rating: transformer.rating,
                                   rank: transformer.rank,
                                   isBenched: dataController.transformerBenchedState(withId: id))
        }
    }
}
