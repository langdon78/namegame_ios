//
//  ViewController.swift
//  NameGame
//
//  Created by Matt Kauper on 3/8/16.
//  Copyright © 2016 WillowTree Apps. All rights reserved.
//

import UIKit

final class NameGameViewController: UIViewController {

    @IBOutlet weak var outerStackView: UIStackView!
    @IBOutlet weak var innerStackView1: UIStackView!
    @IBOutlet weak var innerStackView2: UIStackView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet var imageButtons: [FaceButton]!
    @IBOutlet weak var progressIndicatorView: UIProgressView!
    @IBOutlet weak var scoreLabel: UILabel!
    
    lazy var nameGame: NameGame = { return NameGame() }()
    var images: [(image: UIImage, id: String)] = [] {
        didSet {
            let percent = calculateLoadProgress(for: images.count)
            setProgressIndicator(with: percent)
            displayImagesIfNeeded()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameGame.delegate = self
        hideProgressIndicator()
        
        let orientation: UIDeviceOrientation = self.view.frame.size.height > self.view.frame.size.width ? .portrait : .landscapeLeft
        configureSubviews(orientation)
    }

    @IBAction func faceTapped(_ button: FaceButton) {
        let answer = nameGame.evaluateAnswer(for: button.id)
        showAnswerFeedback(correct: answer)
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.nameGame.shuffle()
        }
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
        if images.count == nameGame.numberPeople {
            DispatchQueue.main.async { [weak self] in
                guard let me = self else { return }
                me.fadeInImages()
                me.imageButtons.forEach {
                    $0.showFace(me.images[$0.tag].image, for: me.images[$0.tag].id)
                }
                me.resetImageCache()
                me.hideProgressIndicator()
            }
        }
    }
    
    private func showAnswerFeedback(correct: Bool) {
        view.backgroundColor = correct ? .green : .red
    }
    
    private func resetImageCache() {
        self.images.removeAll()
    }
    
    private func gatherImagesForDisplay() {
        imageButtons.forEach { button in
            nameGame.imageData(for: button.tag) { [weak self] (data, id) in
                guard let image = UIImage(data: data) else { return }
                self?.images.append((image, id))
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
}
