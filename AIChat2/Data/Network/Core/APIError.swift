//
//  APIError.swift
//  AIChat2
//

import Foundation

struct APIError: Error, Hashable, Sendable {
    
    let kind: ErrorKind
    let retryAfter: Duration?
    
    init(kind: ErrorKind, retryAfter: Duration? = nil) {
        self.kind = kind
        self.retryAfter = retryAfter
    }
}
