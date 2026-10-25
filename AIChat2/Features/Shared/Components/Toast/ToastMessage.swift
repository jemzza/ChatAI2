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
    nonisolated static func haptic(for toast: ToastMessage?) -> Haptics.Kind? {
        switch toast?.kind {
            case .success: .success
            case .failure: .error
            case nil: nil
        }
    }
}
