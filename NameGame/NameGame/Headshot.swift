//
//  Headshot.swift
//  NameGame
//
//  Created by James Langdon on 9/11/18.
//  Copyright © 2018 WillowTree Apps. All rights reserved.
//

import UIKit

struct Headshot: Codable, Equatable {
    var id: String
    var type: String
    var mimeType: String?
    var url: String?
    var alt: String
    var height: Int?
    var width: Int?
}

extension Headshot {
    var urlFull: URL? {
        guard let url = url else { return nil }
        let fullPath = "http:\(url)"
        return URL(string: fullPath)
    }
    
    func image(completionHandler: @escaping (UIImage) -> Void) {
        guard let url = urlFull else { return }
        NetworkManager.shared.blob(at: url) { (result: Result<UIImage>) in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    completionHandler(image)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
