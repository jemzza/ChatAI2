import AVFoundation
import SwiftUI
import UIKit

struct MasonryGrid<Item: Identifiable, Cell: View>: View {
    let items: [Item]
    let width: CGFloat
    let spacing: CGFloat
    @ViewBuilder let cell: (Item) -> Cell
    let height: (Item, CGFloat) -> CGFloat
    
    var body: some View {
        let columnWidth = max((width - spacing) / 2, 0)
        let columns = split(columnWidth: columnWidth)
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<2, id: \.self) { column in
                LazyVStack(spacing: spacing) {
                    ForEach(columns[column]) { item in
                        cell(item).frame(width: columnWidth, height: height(item, columnWidth))
                    }
                }
                .frame(width: columnWidth)
            }
        }
    }
    
    private func split(columnWidth: CGFloat) -> [[Item]] {
        var columns: [[Item]] = [[], []]
        var heights: [CGFloat] = [0, 0]
        for item in items {
            let column = heights[0] <= heights[1] ? 0 : 1
            columns[column].append(item)
            heights[column] += height(item, columnWidth) + spacing
        }
        return columns
    }
}

struct VideoHistoryCard: View {
    let generation: VideoGeneration
    let thumbnails: any VideoThumbnailing
    let media: any MediaStoring
    var player: AVPlayer?
    let onOpen: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        Button(action: onOpen) {
            ZStack {
                background
                overlay
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topLeading) { badge.padding(8) }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    @ViewBuilder
    private var background: some View {
        switch generation.status {
            case .succeeded:
                VideoThumbnailView(url: resultURL, thumbnails: thumbnails)
                    .overlay { PreviewVideoLayer(player: player) }
            case .creating, .generating, .failed:
                LocalImageView(url: media.sourceImageURL(named: generation.sourceImageName))
                    .blur(radius: 6)
                    .overlay(Color.appBackground.opacity(0.55))
        }
    }
    
    @ViewBuilder
    private var overlay: some View {
        switch generation.status {
            case .creating, .generating:
                VStack(spacing: 8) {
                    ProgressView().tint(.appAccent)
                    Text("Generating…")
                        .font(AppFont.captionMedium)
                        .foregroundStyle(Color.appAccent.opacity(0.85))
                }
            case .failed:
                VStack(spacing: 8) {
                    Text("Something went wrong")
                        .font(AppFont.caption)
                        .foregroundStyle(Color.appAccent.opacity(0.85))
                        .multilineTextAlignment(.center)
                    Button(action: onRetry) {
                        Text("Try again")
                            .font(AppFont.captionMedium)
                            .foregroundStyle(Color.appAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(8)
            case .succeeded:
                EmptyView()
        }
    }
    
    @ViewBuilder
    private var badge: some View {
        switch generation.status {
            case .creating, .generating:
                StatusBadge(title: "In progress", color: .appGradientStart)
            case .failed:
                StatusBadge(title: "Error", color: .red)
            case .succeeded:
                if !generation.isViewed {
                    StatusBadge(title: "New", color: .green)
                }
        }
    }
    
    private var resultURL: URL? {
        generation.localVideoName.flatMap(media.localVideoURL(named:)) ?? generation.videoURL
    }
}

private struct StatusBadge: View {
    let title: LocalizedStringKey
    let color: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title)
                .font(AppFont.captionMedium)
                .foregroundStyle(color)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .padding(.vertical, 4)
        .background(Color.appBackground.opacity(0.7), in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.5)))
    }
}

private struct LocalImageView: View {
    let url: URL
    @State private var image: UIImage?
    
    var body: some View {
        Color.appSurface
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .clipped()
            .task(id: url) {
                image = await Task.detached(priority: .utility) {
                    UIImage(contentsOfFile: url.path)?.preparingThumbnail(of: CGSize(width: 400, height: 400))
                }.value
            }
    }
}
