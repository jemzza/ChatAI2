import SwiftUI
import UIKit

extension View {
    func photoAccessAlert(isPresented: Binding<Bool>) -> some View {
        modifier(PhotoAccessAlert(isPresented: isPresented))
    }
}

private struct PhotoAccessAlert: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(\.openURL) private var openURL
    
    func body(content: Content) -> some View {
        content.alert("No access to Photos", isPresented: $isPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        } message: {
            Text("Allow access to your photos in Settings to upload an image.")
        }
    }
}
