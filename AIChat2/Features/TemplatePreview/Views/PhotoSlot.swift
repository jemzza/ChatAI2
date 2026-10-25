import SwiftUI
import UIKit

struct PhotoSlot: View {
    let state: TemplatePreviewViewModel.PhotoState
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        ZStack {
            switch state {
                case .empty:
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(Color.appAccent)
                            .frame(width: 100, height: 100)
                            .background(Color.appSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(AppGradient.primary, lineWidth: 1))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel(Text("Add photo"))
                case .loading:
                    ProgressView()
                        .tint(.appGradientEnd)
                        .frame(width: 100, height: 100)
                        .background(Color.appSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel(Text("Uploading photo"))
                case let .loaded(data):
                    PhotoThumbnail(data: data)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(alignment: .topTrailing) {
                            Button(action: onRemove) {
                                Image("IconCloseGradient")
                                    .frame(width: 24, height: 24)
                                    .padding(4)
                                    .background(Color.white, in: Circle())
                            }
                            .offset(x: 8, y: -8)
                            .accessibilityLabel(Text("Remove photo"))
                        }
            }
        }
        .frame(width: 100, height: 100)
        .animation(.easeInOut(duration: 0.2), value: state)
    }
}

private struct PhotoThumbnail: View {
    let data: Data
    @State private var image: UIImage?
    
    var body: some View {
        Color.appSurface
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .clipped()
            .task(id: data) {
                image = await Task.detached(priority: .userInitiated) {
                    UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 300, height: 300))
                }.value
            }
    }
}
