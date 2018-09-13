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
    var image: UIImage
}

final class NameGameViewController: UIViewController {

    @IBOutlet weak var outerStackView: UIStackView!
    @IBOutlet weak var innerStackView1: UIStackView!
    @IBOutlet weak var innerStackView2: UIStackView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet var imageButtons: [FaceButton]!
    @IBOutlet weak var progressIndicatorView: UIProgressView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameModeLabel: UILabel!
    
    lazy var nameGame: NameGame = { return NameGame() }()
    var buttonProfiles: [ButtonProfile] = [] {
        didSet {
            let percent = calculateLoadProgress(for: buttonProfiles.count)
            setProgressIndicator(with: percent)
            displayImagesIfNeeded()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameGame.delegate = self
        hideProgressIndicator()
        gameModeLabel.text = nameGame.gameMode.rawValue
        
        let orientation: UIDeviceOrientation = self.view.frame.size.height > self.view.frame.size.width ? .portrait : .landscapeLeft
        configureSubviews(orientation)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    @IBAction func faceTapped(_ button: FaceButton) {
        guard let id = button.buttonProfile?.id else { return }
        let answer = nameGame.evaluateAnswer(for: id)
        showAnswerFeedback(correct: answer)
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.nameGame.shuffle()
        }
    }
    
    @IBAction func newGame(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
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
        if buttonProfiles.count == nameGame.numberPeople {
            DispatchQueue.main.async { [weak self] in
                self?.imageButtons.forEach { $0.alpha = 1.0 }
                guard let me = self else { return }
                me.fadeInImages()
                me.imageButtons.forEach {
                    if self?.nameGame.gameMode == .reverseMode {
                        let image = me.getImageWithColor(color: .white, size: CGSize(width: 340, height: 340))
                        let buttonProfile = ButtonProfile(id: me.buttonProfiles[$0.tag].id, name: me.buttonProfiles[$0.tag].name, image: image)
                        $0.configure(for: buttonProfile, reverse: true)
                        print(me.nameGame.visibleProfiles[me.nameGame.answerIndex])
                        if me.buttonProfiles[$0.tag].id == me.firstAvailableNonanswer() {
                            var newButtonProfile = me.buttonProfiles[$0.tag]
                            newButtonProfile.image = me.getAnswerImage()!
                            $0.configure(for: newButtonProfile, reverse: false)
                        }
                    } else {
                        $0.configure(for: me.buttonProfiles[$0.tag], reverse: false)
                    }
                }
                me.resetImageCache()
                me.hideProgressIndicator()
            }
        }
    }
    
    func getAnswerImage() -> UIImage? {
        let reverseId = nameGame.reverseProfile.id
        return buttonProfiles.first(where: { $0.id == reverseId })?.image
    }
    
    func firstAvailableNonanswer() -> String? {
        let reverseId = nameGame.reverseProfile.id
        return buttonProfiles.first(where: { $0.id != reverseId })?.id
    }
    
    func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func showAnswerFeedback(correct: Bool) {
        view.backgroundColor = correct ? .green : .red
    }
    
    private func resetImageCache() {
        self.buttonProfiles.removeAll()
    }
    
    private func gatherImagesForDisplay() {
        imageButtons.forEach { button in
            nameGame.profileData(for: button.tag) { [weak self] (data, id, name) in
                guard let image = UIImage(data: data) else { return }
                let buttonProfile = ButtonProfile(id: id, name: name, image: image)
                self?.buttonProfiles.append(buttonProfile)
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
}
