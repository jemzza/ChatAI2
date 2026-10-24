//
//  AFError.swift
//  AIChat2
//

import Foundation
import Alamofire

extension AFError {
    
    func asAPIError(response: HTTPURLResponse?) -> Error {
        if isExplicitlyCancelledError {
            return CancellationError()
        }
        
//        if let response, let error = APIErrorMapper.error(statusCode: response.statusCode,
//                                                          headers: response.allHeaderFields) {
//            return error
//        }
        
        if let urlError = underlyingError as? URLError {
            return urlError.code == .cancelled ? CancellationError() : APIErrorMapper.error(urlError)
        }
        
        return APIError(kind: .unknown)
    }
}
