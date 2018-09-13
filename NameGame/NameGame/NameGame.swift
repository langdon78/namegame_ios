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
    func hideFace(for id: String)
}

class NameGame {
    // Constants
    let questionPrefixText = "Who is "
    var numberPeople = 6
    
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
    var answerIndex: Int = 0
    var timer: Timer?
    
    // Derived
    var allProfiles: [Profile] = [] {
        didSet {
            updateView()
        }
    }
    
    var hiddenProfiles: [Profile] = []
    
    var visibleProfiles: [Profile] {
        guard allProfiles.count > numberPeople else { return [] }
        return Array(allProfiles[0..<numberPeople])
    }
    
    var reverseProfile: Profile {
        return visibleProfiles[answerIndex]
    }
    
    var answerFullName: String {
        answerIndex = numericCast(arc4random_uniform(numericCast(visibleProfiles.count)))
        return gameMode == .reverseMode ? "this" : visibleProfiles[answerIndex].fullName
    }
    
    var questionLabelText: String {
        return questionPrefixText + answerFullName + "?"
    }
    
    init(networkManager: NetworkManager = NetworkManager.shared,
         delegate: NameGameDelegate? = nil,
         gameMode: GameMode = .normalMode) {
        self.networkManager = networkManager
        self.delegate = delegate
        self.gameMode = gameMode
        loadGameData(completion: processGameMode)
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
    
    private func processGameMode() {
        switch gameMode {
        case .hintMode:
            startTimer()
        default:
            break
        }
    }
    
    @objc private func hideFaces() {
        guard let profileToRemove = self.visibleProfiles.filter({ !self.hiddenProfiles.contains($0) }).first(where: { $0.id != self.visibleProfiles[self.answerIndex].id }) else {
            stopTimer()
            return
        }
        hiddenProfiles.append(profileToRemove)
        self.delegate?.hideFace(for: profileToRemove.id)
    }
    
    private func startTimer() {
        if timer != nil { timer?.invalidate() }
        let date = Date().addingTimeInterval(3)
        timer = Timer(fireAt: date, interval: 3, target: self, selector: #selector(hideFaces), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    private func stopTimer() {
        timer?.invalidate()
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
        let cleanProfiles = filterProfilesWithNoImages(profiles)
        switch gameMode {
        case .mattMode: allProfiles = cleanProfiles.filter( {$0.firstName.prefix(3) == "Mat"} )
        case .teamMode: allProfiles = cleanProfiles.filter({ $0.jobTitle != nil })
        default:
            allProfiles = cleanProfiles
        }
    }
    
}


// MARK: - Public API
extension NameGame {
    
    public func profileData(for id: Int, completionHandler: @escaping (Data, String, String) -> Void) {
        guard let profile = profile(for: id),
            let url = profile.headshot.urlFull else { return }

        NetworkManager.shared.retrieve(from: url) { (result: Result<Data>) in
            switch result {
            case .success(let image):
                completionHandler(image, profile.id, profile.fullName)
            case .failure(let error):
                print(error)
            }
        }
    }

    public func shuffle() {
        processGameMode()
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
        if visibleProfiles[answerIndex].id == id {
            correctAnswers += 1
            totalAnswers += 1
            return true
        }
        totalAnswers += 1
        return false
    }
    
}
