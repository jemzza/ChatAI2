//
//  JSONDecoder+Extensions.swift
//  AIChat2
//

import Foundation

nonisolated extension JSONDecoder {
    
    static var snakeCase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
