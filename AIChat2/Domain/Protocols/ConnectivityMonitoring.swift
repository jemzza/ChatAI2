//
//  ConnectivityMonitoring.swift
//  AIChat2
//

import Foundation

nonisolated protocol ConnectivityMonitoring: Sendable {
    var isOnline: Bool { get }
    func updates() -> AsyncStream<Bool>
}
