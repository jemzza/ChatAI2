import SwiftUI

enum ErrorText {
    static func key(for kind: ErrorKind?) -> LocalizedStringKey {
        switch kind ?? .unknown {
            case .offline: "No internet connection. Check your connection and try again."
            case .rateLimited: "Too many requests. Please wait a moment and try again."
            case .paymentRequired: "The AI service is temporarily unavailable. Please try again later."
            case .unauthorized, .forbidden: "Access to the AI service was denied. Please try again later."
            case .server, .notFound: "The server is having trouble right now. Please try again."
            case .validation, .decoding, .unknown: "Something went wrong. Please try again."
        }
    }
}
