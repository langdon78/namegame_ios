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
    func showAlert(for error: Error)
}

final class NameGame {
    // MARK: Constants
    private let questionPrefixText = "Who is "
    public let numberPeople = 6
    
    // MARK: Public
    public var gameMode: GameMode
    public weak var delegate: NameGameDelegate?
    
    // MARK: Private
    private var correctAnswers: Int = 0
    private var totalAnswers: Int = 0 {
        didSet {
            delegate?.updateScoreLabel(with: "\(correctAnswers) / \(totalAnswers)")
        }
    }
    private var networkManager: NetworkManager
    private var answerIndex: Int = 0
    private var allProfiles: [Profile] = [] {
        didSet {
            updateView()
        }
    }
    
    // Hint Mode
    private var timer: Timer?
    private var profilesToHide: [Profile] = []
    
    // MARK: Derived
    public var questionLabelText: String {
        return questionPrefixText + answerFullName + "?"
    }
    
    private var visibleProfiles: [Profile] {
        guard allProfiles.count > numberPeople else { return [] }
        return Array(allProfiles[0..<numberPeople])
    }
    
    private var reverseModeProfiles: [Profile] {
        return prepareProfilesForReverseMode()
    }
    
    private var displayableProfiles: [Profile] {
        return gameMode == .reverseMode ? reverseModeProfiles : visibleProfiles
    }
    
    private var answerProfile: Profile {
        return visibleProfiles[answerIndex]
    }
    
    private var answerFullName: String {
        return gameMode == .reverseMode ? "this" : visibleProfiles[answerIndex].fullName
    }
    
    init(networkManager: NetworkManager = NetworkManager.shared,
         delegate: NameGameDelegate? = nil,
         gameMode: GameMode = .normalMode) {
        self.networkManager = networkManager
        self.delegate = delegate
        self.gameMode = gameMode
        loadGameData()
    }

    // MARK: Game Configuration
    private func loadGameData() {
        networkManager.items(at: Endpoint.profile.url) { [weak self] (result: Result<[Profile]>) in
            switch result {
            case .success(let profiles):
                self?.filterProfiles(profiles)
            case .failure(let error):
                print(error)
                self?.delegate?.showAlert(for: error)
            }
        }
    }
    
    private func configureGameMode() {
        switch gameMode {
        case .hintMode:
            startTimer()
        default:
            break
        }
    }
    
    private func filterProfiles(_ profiles: [Profile]) {
        let cleanProfiles = filterProfilesWithNoImages(profiles)
        switch gameMode {
        case .mattMode: startGame(with: cleanProfiles.filter( {$0.firstName.prefix(3) == "Mat"} ))
        case .teamMode: startGame(with: cleanProfiles.filter({ $0.jobTitle != nil }))
        default:
            startGame(with: cleanProfiles)
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
        guard displayableProfiles.count >= id else { return nil }
        return displayableProfiles[id]
    }
    
    private func getNewAnswer() {
        answerIndex = numericCast(arc4random_uniform(numericCast(visibleProfiles.count)))
    }
    
    private func shuffle(_ profiles: [Profile] = []) {
        var shuffled = profiles.isEmpty ? allProfiles : profiles
        guard shuffled.count > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(shuffled.indices, stride(from: shuffled.count, to: 0, by: -1)) {
            let randomIndex: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let newIndex = shuffled.index(firstUnshuffled, offsetBy: randomIndex)
            shuffled.swapAt(firstUnshuffled, newIndex)
        }
        allProfiles = shuffled
    }
    
    private func startGame(with profiles: [Profile]) {
        nextTurn(with: profiles)
    }
    
}


// MARK: - Public API
extension NameGame {
    
    public func profileData(for id: Int, completionHandler: @escaping (Data, String, String) -> Void) {
        guard let profile = profile(for: id) else { return }
        guard let url = profile.headshot.urlFull else {
            completionHandler(Data(), profile.id, profile.fullName)
                return
        }

        NetworkManager.shared.retrieve(from: url) { [weak self] (result: Result<Data>) in
            switch result {
            case .success(let image):
                completionHandler(image, profile.id, profile.fullName)
            case .failure(let error):
                print(error)
                self?.delegate?.showAlert(for: error)
            }
        }
    }

    public func nextTurn(with profiles: [Profile] = []) {
        configureGameMode()
        shuffle(profiles)
        getNewAnswer()
    }
    
    public func evaluateAnswer(for id: String) -> Bool {
        if displayableProfiles[answerIndex].id == id {
            correctAnswers += 1
            totalAnswers += 1
            return true
        }
        totalAnswers += 1
        return false
    }
    
    public func cleanUpGame() {
        timer?.invalidate()
        profilesToHide.removeAll()
    }
    
}

// MARK: - Hint Mode Methods
extension NameGame {
    
    @objc private func hideFaces() {
        guard let profileToRemove = self.displayableProfiles.filter({ !self.profilesToHide.contains($0) }).first(where: { $0.id != self.displayableProfiles[self.answerIndex].id }) else {
            stopTimer()
            return
        }
        profilesToHide.append(profileToRemove)
        self.delegate?.hideFace(for: profileToRemove.id)
    }
    
    private func startTimer() {
        if timer != nil { stopTimer() }
        let date = Date().addingTimeInterval(3)
        timer = Timer(fireAt: date, interval: 3, target: self, selector: #selector(hideFaces), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    private func stopTimer() {
        profilesToHide.removeAll()
        timer?.invalidate()
    }
    
}

// MARK: - Reverse Mode Methods
extension NameGame {
    
    // Only display names for all but answer image
    private func clearUrlsForReverseMode(_ profiles: [Profile]) -> [Profile] {
        return profiles.map {
            var profile = $0
            profile.headshot.url = nil
            return profile
        }
    }
    
    // Swap answer image with non-answer.
    // Selectable answers will be shown with names,
    // instead of image
    private func prepareProfilesForReverseMode() -> [Profile] {
        var visible = visibleProfiles
        // Grab answer image for later
        let answerImageUrl = visible[answerIndex].headshot.url
        visible = clearUrlsForReverseMode(visible)
        // Find nearest index for non-answer person
        guard let nextAvailableIndex = visible.index(where: { $0.id != answerProfile.id }) else { return visible }
        // Apply face image to non-answer person
        visible[nextAvailableIndex].headshot.url = answerImageUrl
        return visible
    }
    
}
