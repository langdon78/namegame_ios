//
//  NetworkManager.swift
//  NameGame
//
//  Created by James Langdon on 9/11/18.
//  Copyright © 2018 WillowTree Apps. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)
}

enum ResponseError: Error {
    case missingData
}

enum HTTPRequestMethod: String {
    case post
    case get
}

struct HTTPRequest {
    var urlString: String
    var requestMethod: HTTPRequestMethod
    var url: URL {
        return URL(string: urlString)!
    }
}

final class NetworkManager {
    static let shared: NetworkManager = NetworkManager()
    
    func send<T: Codable>(urlRequest: URLRequest, completionHandler: @escaping (Result<[T]>) -> ()) {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            if let networkError = error {
                completionHandler(.failure(networkError))
                print("Network error from \(#function): \(networkError).")
            }
            guard let data = data else {
                completionHandler(.failure(ResponseError.missingData))
                return
            }
            do {
                let responseData = try JSONDecoder().decode([T].self, from: data)
                completionHandler(.success(responseData))
            } catch {
                print("An error occured parsing response data: \(error)")
            }
        }).resume()
    }
    
    static func request(for request: HTTPRequest) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.requestMethod.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return urlRequest
    }
}
