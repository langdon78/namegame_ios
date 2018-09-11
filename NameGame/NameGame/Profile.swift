//
//  Profile.swift
//  NameGame
//
//  Created by James Langdon on 9/11/18.
//  Copyright © 2018 WillowTree Apps. All rights reserved.
//

import Foundation

struct Profile: Codable, Equatable {
    var id: String
    var type: String
    var slug: String
    var jobTitle: String?
    var firstName: String
    var lastName: String
    var headshot: Headshot
    var socialLinks: [SocialLink]
}
