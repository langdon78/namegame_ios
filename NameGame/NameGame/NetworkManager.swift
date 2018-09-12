//
//  NetworkManager.swift
//  NameGame
//
//  Created by James Langdon on 9/11/18.
//  Copyright © 2018 WillowTree Apps. All rights reserved.
//

import Foundation

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

final class NetworkManager {
    static let shared: NetworkManager = NetworkManager()
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    private init() {}
    
    public func items<Decoded>(at url: URL, completionHandler: @escaping NetworkResponse<[Decoded]>) where Decoded: Codable {
        retrieve(from: url) { [weak self] result in
            switch result {
            case .success(let data):
                guard let entities: [Decoded] = self?.decode(for: data) else {
                    completionHandler(.failure(ResponseError.unableToParseResponse))
                    return
                }
                completionHandler(.success(entities))
            case .failure(let error): completionHandler(.failure(error))
            }
        }
    }
    
    public func retrieve(from url: URL, completionHandler: @escaping NetworkResponse<Data>) {
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

// MARK: Decode helper method
extension NetworkManager {
    fileprivate func decode<T>(for data: Data) -> [T]? where T: Codable {
        do {
            let decoded = try JSONDecoder().decode([T].self, from: data)
            return decoded
        } catch {
            print(error)
            return nil
        }
    }
}
