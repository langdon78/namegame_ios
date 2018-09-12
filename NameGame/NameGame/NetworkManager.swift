//
//  NetworkManager.swift
//  NameGame
//
//  Created by James Langdon on 9/11/18.
//  Copyright © 2018 WillowTree Apps. All rights reserved.
//

import UIKit

typealias NetworkResponse<T> = (Result<T>) -> Void

enum Result<T> {
    case success(T)
    case failure(Error)
}

enum ResponseError: Error {
    case missingData
    case unableToParseResponse
}

enum Endpoint: String {
    case profile = "profiles/"
    case base = "https://willowtreeapps.com/api/v1.0/"
    
    var url: URL {
        let path = Endpoint.base.rawValue + rawValue
        return URL(string: path)!
    }
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

protocol Instantiable {
    init?(data: Data)
}

extension UIImage: Instantiable {}

final class NetworkManager {
    static let shared: NetworkManager = NetworkManager()
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    public func items<T>(at url: URL, completionHandler: @escaping NetworkResponse<[T]>) where T: Codable {
        retrieve(from: url) { [weak self] result in
            switch result {
            case .success(let data):
                guard let entities: [T] = self?.entities(for: data) else {
                    completionHandler(.failure(ResponseError.unableToParseResponse))
                    return
                }
                completionHandler(.success(entities))
            case .failure(let error): completionHandler(.failure(error))
            }
        }
    }
    
    public func blob<T>(at url: URL, completionHandler: @escaping NetworkResponse<T>) where T: Instantiable {
        retrieve(from: url) { [weak self] result in
            switch result {
            case .success(let data):
                guard let parsed: T = self?.entity(for: data) else {
                    completionHandler(.failure(ResponseError.unableToParseResponse))
                    return
                }
                completionHandler(.success(parsed))
            case .failure(let error): completionHandler(.failure(error))
            }
        }
    }
    
    private func entity<T>(for data: Data) -> T? where T: Instantiable {
        return T.init(data: data)
    }
    
    private func entities<T>(for data: Data) -> [T]? where T: Codable {
        do {
            let decoded = try JSONDecoder().decode([T].self, from: data)
            return decoded
        } catch {
            print(error)
            return nil
        }
    }
    
    private func retrieve(from url: URL, completionHandler: @escaping NetworkResponse<Data>) {
        let urlRequest = URLRequest(url: url)
        session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            if let networkError = error {
                completionHandler(.failure(networkError))
                print("Network error from \(#function): \(networkError).")
            }
            guard let data = data else {
                completionHandler(.failure(ResponseError.missingData))
                return
            }
            completionHandler(.success(data))
        }).resume()
    }
}
