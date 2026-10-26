import SwiftUI
import UIKit

struct VideoThumbnailView: View {
    let url: URL?
    let thumbnails: any VideoThumbnailing
    var maxPixelSize = 480
    
    @State private var image: UIImage?
    @State private var isLoaded = false
    
    var body: some View {
        Color.appSurface
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                }
            }
            .shimmer(isActive: url != nil && !isLoaded)
            .clipped()
            .task(id: url) {
                guard let url, image == nil else { return }
                let data = await thumbnails.thumbnail(for: url, maxPixelSize: maxPixelSize)
                let decoded = await Task.detached(priority: .userInitiated) {
                    data.flatMap { UIImage(data: $0)?.preparingForDisplay() }
                }.value
                withAnimation(.easeOut(duration: 0.25)) {
                    image = decoded
                    isLoaded = true
                }
            }
    }
}
