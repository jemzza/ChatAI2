//
//  Haptics.swift
//  AIChat2
//

import SwiftUI
import UIKit

enum Haptics {
    enum Kind: Sendable {
        case tap
        case success
        case error
    }
    
    static func play(_ kind: Kind) {
        switch kind {
            case .tap: UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

extension View {
    func haptic<Value: Equatable>(on value: Value, _ kind: @escaping (Value) -> Haptics.Kind?) -> some View {
        onChange(of: value) { newValue in
            if let feedback = kind(newValue) { Haptics.play(feedback) }
        }
    }
}
