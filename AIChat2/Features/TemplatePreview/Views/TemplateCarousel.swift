import SwiftUI

struct TemplateCarousel: View {
    let templates: [VideoTemplate]
    @Binding var index: Int
    let thumbnails: any VideoThumbnailing
    
    private let cardWidth: CGFloat = 331
    private let spacing: CGFloat = 16
    @GestureState private var drag: CGFloat = 0
    
    var body: some View {
        GeometryReader { proxy in
            let step = cardWidth + spacing
            let leading = (proxy.size.width - cardWidth) / 2
            HStack(spacing: spacing) {
                ForEach(Array(templates.enumerated()), id: \.element.id) { offset, template in
                    card(
                        template,
                        isCurrent: offset == index,
                        isNear: abs(offset - index) <= 2,
                        size: CGSize(width: cardWidth, height: proxy.size.height)
                    )
                }
            }
            .offset(x: leading - CGFloat(index) * step + drag)
            .gesture(
                DragGesture()
                    .updating($drag) { value, state, _ in state = value.translation.width }
                    .onEnded { value in
                        let delta = Int((-value.predictedEndTranslation.width / step).rounded())
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            index = min(max(index + max(min(delta, 1), -1), 0), max(templates.count - 1, 0))
                        }
                    }
            )
        }
        .clipped()
    }
    
    @ViewBuilder
    private func card(_ template: VideoTemplate, isCurrent: Bool, isNear: Bool, size: CGSize) -> some View {
        ZStack {
            if isNear {
                VideoThumbnailView(url: template.previewURL, thumbnails: thumbnails, maxPixelSize: 700)
                if isCurrent, let url = template.previewURL {
                    LoopingVideoPlayer(url: url)
                        .transition(.opacity)
                }
            } else {
                Color.appSurface
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
