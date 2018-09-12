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
    
    lazy var nameGame: NameGame = { return NameGame() }()

    override func viewDidLoad() {
        super.viewDidLoad()
        nameGame.delegate = self
        
        let orientation: UIDeviceOrientation = self.view.frame.size.height > self.view.frame.size.width ? .portrait : .landscapeLeft
        configureSubviews(orientation)
    }

    @IBAction func faceTapped(_ button: FaceButton) {
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
    
    func setTransparency(_ visible: Bool, completion: (() -> Void)?) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.outerStackView.alpha = visible ? 0.0 : 1.0
                completion?()
            }
        }
    }
}

extension NameGameViewController: NameGameDelegate {

    func refreshImages() {
        var loaded = 0
        setTransparency(true) {
            for n in 0..<self.imageButtons.count {
                if loaded == 5 { self.setTransparency(false, completion: nil) }
                guard let profile = self.nameGame.profile(for: n) else { return }
                self.nameGame.imageData(for: profile) { [weak self] data in
                    DispatchQueue.main.async {
                        guard let image = UIImage(data: data) else { return }
                        self?.imageButtons[n].showFace(image)
                    }
                }
                loaded += 1
            }
        }
    }
    
    func setQuestionLabelText(with text: String) {
        DispatchQueue.main.async {
            self.questionLabel.text = self.nameGame.questionLabelText
        }
    }
}
