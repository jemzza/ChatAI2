//
//  JSONDecoder+Extensions.swift
//  AIChat2
//

import Foundation

extension JSONDecoder {
    
    static var snakeCase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
