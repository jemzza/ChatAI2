//
//  NetworkConnectivityMonitor.swift
//  AIChat2
//

import Foundation
import Network
import os

nonisolated final class NetworkConnectivityMonitor: ConnectivityMonitoring {
    private struct State {
        var isOnline = true
        var observers: [UUID: AsyncStream<Bool>.Continuation] = [:]
    }
    
    private let monitor = NWPathMonitor()
    private let state = OSAllocatedUnfairLock(initialState: State())
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.update(isOnline: path.status == .satisfied)
        }
        monitor.start(queue: DispatchQueue(label: "NetworkConnectivityMonitor"))
    }
    
    deinit {
        monitor.cancel()
    }
    
    var isOnline: Bool { state.withLock(\.isOnline) }
    
    func updates() -> AsyncStream<Bool> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()
            state.withLock { state in
                state.observers[id] = continuation
                continuation.yield(state.isOnline)
            }
            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { _ = $0.observers.removeValue(forKey: id) }
            }
        }
    }
    
    private func update(isOnline: Bool) {
        state.withLock { state in
            guard state.isOnline != isOnline else { return }
            state.isOnline = isOnline
            for continuation in state.observers.values { continuation.yield(isOnline) }
        }
    }
}
