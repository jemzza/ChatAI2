//
//  ErrorKind.swift
//  AIChat2
//

import Foundation

enum ErrorKind: String, Hashable, Sendable {
    case offline
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case validation
    case rateLimited
    case server
    case decoding
    case unknown
}

struct MessageFailure: Hashable, Sendable {
    let kind: ErrorKind
    let retryAt: Date?
    
    init(kind: ErrorKind, retryAt: Date? = nil) {
        self.kind = kind
        self.retryAt = retryAt
    }
}
