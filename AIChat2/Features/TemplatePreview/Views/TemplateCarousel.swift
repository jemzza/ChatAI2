import SwiftUI

struct TemplateCarousel: View {
    let templates: [VideoTemplate]
    @Binding var index: Int
    let thumbnails: any VideoThumbnailing
    
    private let cardWidth: CGFloat = 331
    private let spacing: CGFloat = 16
    @State private var drag: CGFloat = 0
    @State private var playingIndex: Int?
    
    var body: some View {
        GeometryReader { proxy in
            let step = cardWidth + spacing
            let leading = (proxy.size.width - cardWidth) / 2
            HStack(spacing: spacing) {
                ForEach(Array(templates.enumerated()), id: \.element.id) { offset, template in
                    card(
                        template,
                        isPlaying: offset == playingIndex,
                        isNear: abs(offset - index) <= 2,
                        size: CGSize(width: cardWidth, height: proxy.size.height)
                    )
                }
            }
            .offset(x: leading - CGFloat(index) * step + drag)
            .gesture(
                DragGesture()
                    .onChanged { drag = $0.translation.width }
                    .onEnded { value in
                        let delta = Int((-value.predictedEndTranslation.width / step).rounded())
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            index = min(max(index + max(min(delta, 1), -1), 0), max(templates.count - 1, 0))
                            drag = 0
                        }
                    }
            )
        }
        .clipped()
        .task(id: index) {
            playingIndex = nil
            guard (try? await Task.sleep(for: .milliseconds(400))) != nil else { return }
            playingIndex = index
        }
    }
    
    @ViewBuilder
    private func card(_ template: VideoTemplate, isPlaying: Bool, isNear: Bool, size: CGSize) -> some View {
        ZStack {
            if isNear {
                VideoThumbnailView(url: template.previewURL, thumbnails: thumbnails, maxPixelSize: 700)
                if isPlaying, let url = template.previewURL {
                    LoopingVideoPlayer(url: url)
                }
            } else {
                Color.appSurface
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
