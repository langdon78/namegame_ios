//
//  NameGame.swift
//  NameGame
//
//  Created by Erik LaManna on 11/7/16.
//  Copyright © 2016 WillowTree Apps. All rights reserved.
//

import Foundation

protocol NameGameDelegate: class {
    func refresh()
}

class NameGame {
    var allProfiles: [Profile] = [] {
        didSet {
            delegate?.refresh()
        }
    }
    
    var visibleProfiles: [Profile] {
        guard allProfiles.count > 5 else { return [] }
        return Array(allProfiles[0...5])
    }

    var networkManager: NetworkManager

    weak var delegate: NameGameDelegate?

    let numberPeople = 6
    
    init(networkManager: NetworkManager = NetworkManager.shared, delegate: NameGameDelegate? = nil) {
        self.networkManager = networkManager
        self.delegate = delegate
        loadGameData { [weak self] in
            self?.delegate?.refresh()
        }
    }
    
    func profile(for id: Int) -> Profile? {
        guard visibleProfiles.count >= id else { return nil }
        return visibleProfiles[id]
    }

    // Load JSON data from API
    func loadGameData(completion: @escaping () -> Void) {
        networkManager.items(at: Endpoint.profile.url) { [weak self] (result: Result<[Profile]>) in
            switch result {
            case .success(let data):
                self?.allProfiles = data
            case .failure(let error):
                print(error)
            }
            completion()
        }
    }
    
    func shuffle() {
        visibleProfiles.forEach({print($0.headshot.height, $0.headshot.width)})
        var shuffled = allProfiles
        guard shuffled.count > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(shuffled.indices, stride(from: shuffled.count, to: 0, by: -1)) {
            let randomIndex: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let newIndex = shuffled.index(firstUnshuffled, offsetBy: randomIndex)
            shuffled.swapAt(firstUnshuffled, newIndex)
        }
        allProfiles = shuffled
    }
}
