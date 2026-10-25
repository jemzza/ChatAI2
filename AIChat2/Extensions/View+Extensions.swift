import SwiftUI

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        font(style.font)
    }
}

extension View {
    @ViewBuilder
    func scrollBounceBehaviorIfAvailable() -> some View {
        if #available(iOS 16.4, *) {
            scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }
}
