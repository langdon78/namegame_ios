//
//  GameType.swift
//  NameGame
//
//  Created by James Langdon on 9/13/18.
//  Copyright © 2018 WillowTree Apps. All rights reserved.
//

import Foundation

enum GameMode: String {
    case normalMode = "Normal Mode"
    case mattMode = "Matt Mode"
    case reverseMode = "Reverse Mode"
    case hintMode = "Hint Mode"
    case teamMode = "Team Mode"
    
    static var all: [GameMode] {
        return [
            .normalMode,
            .mattMode,
            .reverseMode,
            .hintMode,
            .teamMode
        ]
    }
}
