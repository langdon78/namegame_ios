//
//  SocialLink.swift
//  NameGame
//
//  Created by James Langdon on 9/11/18.
//  Copyright © 2018 WillowTree Apps. All rights reserved.
//

import Foundation

struct SocialLink: Codable, Equatable {
    var type: String
    var callToAction: String
    var url: String
}
