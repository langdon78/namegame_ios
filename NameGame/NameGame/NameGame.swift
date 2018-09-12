//
//  NameGame.swift
//  NameGame
//
//  Created by Erik LaManna on 11/7/16.
//  Copyright © 2016 WillowTree Apps. All rights reserved.
//

import Foundation

protocol NameGameDelegate: class {
    func refreshImages()
    func setQuestionLabelText(with text: String)
}

class NameGame {
    // Constants
    let questionPrefixText = "Who is "
    let numberPeople = 6
    
    // Properties
    var networkManager: NetworkManager
    weak var delegate: NameGameDelegate?
    
    // Derived
    var allProfiles: [Profile] = [] {
        didSet {
            updateView()
        }
    }
    
    var visibleProfiles: [Profile] {
        guard allProfiles.count > numberPeople else { return [] }
        return Array(allProfiles[0..<numberPeople])
    }
    
    var name: String {
        let randomIndex: Int = numericCast(arc4random_uniform(numericCast(visibleProfiles.count)))
        return "\(visibleProfiles[randomIndex].firstName) \(visibleProfiles[randomIndex].lastName)"
    }
    
    var questionLabelText: String {
        return questionPrefixText + name + "?"
    }
    
    init(networkManager: NetworkManager = NetworkManager.shared, delegate: NameGameDelegate? = nil) {
        self.networkManager = networkManager
        self.delegate = delegate
        loadGameData { [weak self] in self?.updateView() }
    }

    // Load JSON data from API
    private func loadGameData(completion: @escaping () -> Void) {
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
    
    private func updateView() {
        delegate?.refreshImages()
        delegate?.setQuestionLabelText(with: questionLabelText)
    }
    
}


// MARK: - Public API
extension NameGame {
    
    public func profile(for id: Int) -> Profile? {
        guard visibleProfiles.count >= id else { return nil }
        return visibleProfiles[id]
    }
    
    public func imageData(for profile: Profile, completionHandler: @escaping (Data) -> Void) {
        guard let url = profile.headshot.urlFull else { return }
        NetworkManager.shared.retrieve(from: url) { (result: Result<Data>) in
            switch result {
            case .success(let image):
                completionHandler(image)
            case .failure(let error):
                print(error)
            }
        }
    }

    public func shuffle() {
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
