//
//  Endpoint.swift
//  AIChat2
//

import Foundation

nonisolated struct Endpoint: Sendable {
    
    enum Body: Sendable {
        case none
        case json(Data)
        case multipart(MultipartBody)
    }
    
    var method: HTTPMethod
    var path: String
    var query: [URLQueryItem] = []
    var body: Body = .none
}

nonisolated extension Endpoint {
    
    static func get(_ path: String, query: [URLQueryItem] = []) -> Endpoint {
        Endpoint(method: .get, path: path, query: query)
    }
    
    static func post(_ path: String, json: some Encodable) throws -> Endpoint {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return Endpoint(method: .post, path: path, body: .json(try encoder.encode(json)))
    }
    
    static func post(_ path: String, multipart: MultipartBody) -> Endpoint {
        Endpoint(method: .post, path: path, body: .multipart(multipart))
    }
}
