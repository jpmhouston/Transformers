//
//  Fight.swift
//  Transformers
//
//  Created by Pierre Houston on 2020-06-26.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import Foundation

// todo: add fight logic here

extension Transformer {
    
    enum FightResult {
        case win, loss, tie, destruction
    }
    
    func fight(against opponent: Transformer) -> FightResult {
        // perhaps prevent transformers on the same team from fighting? currently its allowed
        
        if isSpecial && opponent.isSpecial {
            return .destruction
        } else if isSpecial {
            return .win
        } else if opponent.isSpecial {
            return .loss
        }
            
        else if courage >= opponent.courage + 4 {
            return .win
        } else if strength >= opponent.strength + 3 {
            return .win
        } else if skill >= opponent.skill + 3 {
            return .win
        } else if courage + 4 <= opponent.courage {
            return .loss
        } else if strength + 3 <= opponent.strength {
            return .loss
        } else if skill + 3 <= opponent.skill {
            return .loss
        }
        
        else if rating > opponent.rating {
            return .win
        } else if rating < opponent.rating {
            return .loss
        } else {
            return .tie
        }
    }
    
}
