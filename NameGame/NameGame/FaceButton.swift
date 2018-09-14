//
//  FaceButton.swift
//  NameGame
//
//  Created by Intern on 3/11/16.
//  Copyright © 2016 WillowTree Apps. All rights reserved.
//

import Foundation
import UIKit

open class FaceButton: UIButton {

    var buttonProfile: ButtonProfile?
    var tintView: UIView = UIView(frame: CGRect.zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        imageView?.contentMode = .scaleAspectFill
        titleLabel?.alpha = 0.0

        tintView.alpha = 0.0
        tintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tintView)

        tintView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        tintView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        tintView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tintView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    func configure(for buttonProfile: ButtonProfile, titleOnly: Bool) {
        self.buttonProfile = buttonProfile
        if titleOnly {
            setBackgroundImage(buttonProfile.image, for: .normal)
            setImage(nil, for: .normal)
            setTitle(buttonProfile.name, for: .normal)
            titleLabel?.alpha = 1.0
            titleLabel?.textAlignment = .center
        } else {
            setImage(buttonProfile.image, for: .normal)
            titleLabel?.alpha = 0.0
        }
    }
}
