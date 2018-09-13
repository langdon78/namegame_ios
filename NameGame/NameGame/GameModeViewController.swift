//
//  GameModeViewController.swift
//  NameGame
//
//  Created by James Langdon on 9/13/18.
//  Copyright © 2018 WillowTree Apps. All rights reserved.
//

import UIKit

class GameModeViewController: UIViewController {
    @IBOutlet var gameModeButtonCollection: [GameModeButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareButtons()
    }
    
    func prepareButtons() {
        gameModeButtonCollection.enumerated().forEach {
            $0.element.gameMode = GameMode.all[$0.offset]
            $0.element.setTitle(GameMode.all[$0.offset].rawValue, for: .normal)
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nameGameViewController = segue.destination as? NameGameViewController else { return }
        if let gameModeButton = sender as? GameModeButton,
            let gameMode = gameModeButton.gameMode {
            nameGameViewController.nameGame = NameGame(gameMode: gameMode)
        }
    }

}
