//
//  ViewController.swift
//  NameGame
//
//  Created by Matt Kauper on 3/8/16.
//  Copyright © 2016 WillowTree Apps. All rights reserved.
//

import UIKit

struct ButtonProfile {
    var id: String
    var name: String
    var image: UIImage?
}

final class NameGameViewController: UIViewController {

    // MARK: Storyboard Inputs
    @IBOutlet private weak var outerStackView: UIStackView!
    @IBOutlet private weak var innerStackView1: UIStackView!
    @IBOutlet private weak var innerStackView2: UIStackView!
    @IBOutlet private weak var questionLabel: UILabel!
    @IBOutlet private var imageButtons: [FaceButton]!
    @IBOutlet private weak var progressIndicatorView: UIProgressView!
    @IBOutlet private weak var scoreLabel: UILabel!
    @IBOutlet private weak var gameModeLabel: UILabel!
    
    // MARK: Properties
    lazy var nameGame: NameGame = { return NameGame() }()
    
    private var buttonProfileCache: [ButtonProfile] = [] {
        didSet {
            let percent = calculateLoadProgress(for: buttonProfileCache.count)
            setProgressIndicator(with: percent)
            displayImagesIfNeeded()
        }
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameGame.delegate = self
        hideProgressIndicator()
        gameModeLabel.text = nameGame.gameMode.rawValue
        
        let orientation: UIDeviceOrientation = self.view.frame.size.height > self.view.frame.size.width ? .portrait : .landscapeLeft
        configureSubviews(orientation)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        nameGame.cleanUpGame()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    // MARK: Storyboard Actions
    @IBAction func faceTapped(_ button: FaceButton) {
        guard let id = button.buttonProfile?.id else { return }
        let answer = nameGame.evaluateAnswer(for: id)
        showAnswerFeedback(correct: answer)
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.nameGame.nextTurn()
        }
    }
    
    @IBAction func newGame(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Orientation Methods
    func configureSubviews(_ orientation: UIDeviceOrientation) {
        if orientation.isLandscape {
            outerStackView.axis = .vertical
            innerStackView1.axis = .horizontal
            innerStackView2.axis = .horizontal
        } else {
            outerStackView.axis = .horizontal
            innerStackView1.axis = .vertical
            innerStackView2.axis = .vertical
        }

        view.setNeedsLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let orientation: UIDeviceOrientation = size.height > size.width ? .portrait : .landscapeLeft
        configureSubviews(orientation)
    }
    
    // MARK: Implementation
    fileprivate func fadeOutImages(_ visible: Bool = true, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.8) { [weak self] in
                self?.outerStackView.alpha = visible ? 0.0 : 1.0
                if visible { self?.view.backgroundColor = .white }
                completion?()
            }
        }
    }
    
    private func fadeInImages(completion: (() -> Void)? = nil) {
        fadeOutImages(false, completion: completion)
    }
    
    private func setProgressIndicator(with percent: Float) {
        DispatchQueue.main.async {
            self.progressIndicatorView.setProgress(percent, animated: true)
        }
    }
    
    private func calculateLoadProgress(for value: Int) -> Float {
        let total = Float(nameGame.numberPeople)
        return Float(value) / total
    }
    
    private func displayImagesIfNeeded() {
        if buttonProfileCache.count == nameGame.numberPeople {
            DispatchQueue.main.async { [weak self] in
                self?.imageButtons.forEach { $0.alpha = 1.0 }
                self?.fadeInImages()
                self?.imageButtons.forEach { button in
                    self?.configureFaceButton(button)
                }
                self?.resetImageCache()
                self?.hideProgressIndicator()
            }
        }
    }
    
    private func configureFaceButton(_ button: FaceButton) {
        var loadedProfiles = buttonProfileCache
        loadedProfiles.sort(by: {first,_ in first.image != nil })
        let currentProfile = loadedProfiles[button.tag]
        if nameGame.gameMode == .reverseMode {
            let image = emptyImage()
            let buttonProfile = ButtonProfile(id: currentProfile.id, name: currentProfile.name, image: image)
            if currentProfile.image != nil {
                button.configure(for: currentProfile, titleOnly: false)
                button.isUserInteractionEnabled = false
            } else {
                button.configure(for: buttonProfile, titleOnly: true)
            }
        } else {
            button.configure(for: currentProfile, titleOnly: false)
        }
    }
    
    private func showAnswerFeedback(correct: Bool) {
        view.backgroundColor = correct ? .green : .red
    }
    
    private func resetImageCache() {
        self.buttonProfileCache.removeAll()
    }
    
    private func gatherImagesForDisplay() {
        imageButtons.forEach { button in
            nameGame.profileData(for: button.tag) { [weak self] (data, id, name) in
                let image = UIImage(data: data)
                let buttonProfile = ButtonProfile(id: id, name: name, image: image)
                self?.buttonProfileCache.append(buttonProfile)
            }
        }
    }
    
    private func showProgressIndicator() {
        progressIndicatorView.isHidden = false
    }
    
    private func hideProgressIndicator() {
        self.progressIndicatorView.isHidden = true
        self.progressIndicatorView.setProgress(0.0, animated: false)
    }
}

// MARK: - NameGameDelegate
extension NameGameViewController: NameGameDelegate {
    
    func updateScoreLabel(with score: String) {
        DispatchQueue.main.async { [weak self] in
            self?.scoreLabel.text = score
        }
    }

    func refreshImages() {
        fadeOutImages() { [weak self] in
            self?.showProgressIndicator()
            self?.gatherImagesForDisplay()
        }
    }
    
    func setQuestionLabelText(with text: String) {
        DispatchQueue.main.async {
            self.questionLabel.text = self.nameGame.questionLabelText
        }
    }
    
    func hideFace(for id: String) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 2.0) { [weak self] in
                let button = self?.imageButtons.first(where: { $0.buttonProfile?.id == id })
                button?.alpha = 0.0
            }
        }
    }
    
    func showAlert(for error: Error) {
        let alert = UIAlertController(title: "Uh oh...", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - Image Helper
extension NameGameViewController {
    func emptyImage(size: CGSize = CGSize(width: 340, height: 340)) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
