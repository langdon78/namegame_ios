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
            let percent = calculateProgress(for: images.count)
            setProgressIndicator(with: percent)
            displayImagesIfNeeded()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        nameGame.delegate = self
        progressIndicatorView.isHidden = true
        
        let orientation: UIDeviceOrientation = self.view.frame.size.height > self.view.frame.size.width ? .portrait : .landscapeLeft
        configureSubviews(orientation)
    }

    @IBAction func faceTapped(_ button: FaceButton) {
        nameGame.evaluateAnswer(for: button.id)
        nameGame.shuffle()
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
    
    fileprivate func setTransparency(_ visible: Bool, completion: (() -> Void)?) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.8) { [weak self] in
                self?.outerStackView.alpha = visible ? 0.0 : 1.0
                completion?()
            }
        }
    }
    
    private func setProgressIndicator(with percent: Float) {
        DispatchQueue.main.async {
            self.progressIndicatorView.setProgress(percent, animated: true)
        }
    }
    
    private func calculateProgress(for value: Int) -> Float {
        let total = Float(nameGame.numberPeople)
        return Float(value) / total
    }
    
    private func displayImagesIfNeeded() {
        if images.count == nameGame.numberPeople {
            DispatchQueue.main.async { [weak self] in
                guard let me = self else { return }
                me.setTransparency(false, completion: nil)
                me.imageButtons.forEach {
                    $0.showFace(me.images[$0.tag].image, for: me.images[$0.tag].id)
                }
                me.resetImageLoader()
            }
        }
    }
    
    private func resetImageLoader() {
        self.images.removeAll()
        self.progressIndicatorView.isHidden = true
        self.progressIndicatorView.setProgress(0.0, animated: false)
    }
}

extension NameGameViewController: NameGameDelegate {
    
    func updateScoreLabel(with score: String) {
        scoreLabel.text = score
    }

    func refreshImages() {
        setTransparency(true) {
            self.progressIndicatorView.isHidden = false
            self.imageButtons.forEach { button in
                guard let profile = self.nameGame.profile(for: button.tag) else { return }
                self.nameGame.imageData(for: profile) { [weak self] data in
                    guard let image = UIImage(data: data) else { return }
                    self?.images.append((image,profile.id))
                }
            }
        }
    }
    
    func setQuestionLabelText(with text: String) {
        DispatchQueue.main.async {
            self.questionLabel.text = self.nameGame.questionLabelText
        }
    }
}
