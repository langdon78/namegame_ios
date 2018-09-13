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
    func updateScoreLabel(with score: String)
}

class NameGame {
    // Constants
    let questionPrefixText = "Who is "
    let numberPeople = 6
    
    // Properties
    var gameMode: GameMode
    var networkManager: NetworkManager
    weak var delegate: NameGameDelegate?
    var correctAnswers: Int = 0
    var totalAnswers: Int = 0 {
        didSet {
            delegate?.updateScoreLabel(with: "\(correctAnswers) / \(totalAnswers)")
        }
    }
    var nameIndex: Int = 0
    
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
        nameIndex = numericCast(arc4random_uniform(numericCast(visibleProfiles.count)))
        return "\(visibleProfiles[nameIndex].firstName) \(visibleProfiles[nameIndex].lastName)"
    }
    
    var questionLabelText: String {
        return questionPrefixText + name + "?"
    }
    
    init(networkManager: NetworkManager = NetworkManager.shared,
         delegate: NameGameDelegate? = nil,
         gameMode: GameMode = .normal) {
        self.networkManager = networkManager
        self.delegate = delegate
        self.gameMode = gameMode
        loadGameData { print("done loading") }
    }

    // Load JSON data from API
    private func loadGameData(completion: @escaping () -> Void) {
        networkManager.items(at: Endpoint.profile.url) { [weak self] (result: Result<[Profile]>) in
            switch result {
            case .success(let profiles):
                self?.filterProfiles(profiles)
            case .failure(let error):
                print(error)
            }
            completion()
        }
    }
    
    private func filterProfilesWithNoImages(_ profiles: [Profile]) -> [Profile] {
        return profiles.filter({ $0.headshot.url != nil })
    }
    
    private func updateView() {
        delegate?.refreshImages()
        delegate?.setQuestionLabelText(with: questionLabelText)
    }
    
    private func profile(for id: Int) -> Profile? {
        guard visibleProfiles.count >= id else { return nil }
        return visibleProfiles[id]
    }
    
    private func filterProfiles(_ profiles: [Profile]) {
        allProfiles = filterProfilesWithNoImages(profiles)
        switch gameMode {
        case .mattMode: allProfiles = allProfiles.filter( {$0.firstName.prefix(3) == "Mat"} )
        case .teamMode: allProfiles = allProfiles.filter({ $0.jobTitle != nil })
        default: break
        }
    }
    
}


// MARK: - Public API
extension NameGame {
    
    public func imageData(for id: Int, completionHandler: @escaping (Data, String) -> Void) {
        guard let profile = profile(for: id),
            let url = profile.headshot.urlFull else { return }

        NetworkManager.shared.retrieve(from: url) { (result: Result<Data>) in
            switch result {
            case .success(let image):
                completionHandler(image, profile.id)
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
    
    public func evaluateAnswer(for id: String) -> Bool {
        if visibleProfiles[nameIndex].id == id {
            correctAnswers += 1
            totalAnswers += 1
            return true
        }
        totalAnswers += 1
        return false
    }
    
}
