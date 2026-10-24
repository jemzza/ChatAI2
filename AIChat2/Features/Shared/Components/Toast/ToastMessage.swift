//
//  ToastMessage.swift
//  AIChat2
//

import SwiftUI

struct ToastMessage: Equatable, Identifiable {
    enum Kind: Equatable {
        case success
        case failure
    }
    
    let id = UUID()
    let kind: Kind
    let text: LocalizedStringKey
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool { lhs.id == rhs.id }
}

extension ToastMessage {
    @MainActor
    static func haptic(for toast: ToastMessage?) -> (@MainActor () -> Void)? {
        switch toast?.kind {
            case .success: Haptics.success
            case .failure: Haptics.error
            case nil: nil
        }
    }
}
