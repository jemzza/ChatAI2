//
//  Haptics.swift
//  AIChat2
//

import SwiftUI
import UIKit

@MainActor
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

extension View {
    func haptic<Value: Equatable>(on value: Value,
                                  _ feedback: @escaping @MainActor (Value) -> (@MainActor () -> Void)?) -> some View {
        onChange(of: value) { newValue in feedback(newValue)?() }
    }
}
