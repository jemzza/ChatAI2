//
//  NebulaIntercepter.swift
//  AIChat2
//

import Foundation
import Alamofire

struct NebulaIntercepter: RequestInterceptor {
    
    let token: String
    let appID: String
    
    let userID: @Sendable () async -> String
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void) {
        Task {
            var request = urlRequest
            request.headers.add(.authorization(bearerToken: token))
            
            if let url = request.url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                components.queryItems = (components.queryItems ?? []) + [
                    URLQueryItem(name: "app_id", value: appID),
                    URLQueryItem(name: "user_id", value: await userID())
                ]
                
                request.url = components.url
            }
            completion(.success(request))
        }
    }
}
