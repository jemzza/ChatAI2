import Lottie
import SwiftUI
import UIKit

struct GeneratingView: View {
    var body: some View {
        VStack(spacing: 40) {
            GeneratingRing()
                .frame(width: 200, height: 200)
            VStack(spacing: 8) {
                Text("Generating…")
                    .font(AppFont.title3)
                    .foregroundStyle(Color.appAccent)
                Text("We’re creating the best result for you")
                    .font(AppFont.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, AppMetrics.sideInset)
        .accessibilityElement(children: .combine)
    }
}

private struct GeneratingRing: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        LottieView(animation: .named("GeneratingLoader"))
            .playbackMode(reduceMotion ? .paused(at: .progress(0.5)) : .playing(.toProgress(1, loopMode: .loop)))
            .resizable()
            .accessibilityHidden(true)
    }
}

struct ResultPlayer: View {
    let url: URL
    let aspect: VideoAspect
    let isPlaying: Bool
    let onTap: () -> Void
    let onReplace: () -> Void
    
    var body: some View {
        LoopingVideoPlayer(url: url, isPlaying: isPlaying, isMuted: false)
            .aspectRatio(aspect.ratio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .background(Color.appSurface)
            .overlay {
                if !isPlaying {
                    ZStack {
                        Color.black.opacity(0.4)
                        Image(systemName: "play.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.appAccent)
                    }
                    .transition(.opacity)
                }
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onReplace) {
                    HStack(spacing: 8) {
                        Image("IconRefresh").renderingMode(.template)
                        Text("Replace").font(AppFont.subheadline)
                    }
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.appSurface.opacity(0.6), in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
            .contentShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
            .onTapGesture(perform: onTap)
            .animation(.easeInOut(duration: 0.2), value: isPlaying)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text(isPlaying ? "Pause" : "Play"))
    }
}

struct SaveResultCard: View {
    let result: GenerationViewModel.SaveResult
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: result == .saved ? "checkmark" : "xmark")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(result == .saved ? Color.appAccent : Color.red)
                .padding(.bottom, 4)
            Text(result == .saved ? "Video saved" : "Couldn't save video")
                .font(AppFont.headline)
                .foregroundStyle(Color.appAccent)
            Text(result == .saved ? "You can find it in your Photos" : "Please try again")
                .font(AppFont.caption)
                .foregroundStyle(Color.appAccent.opacity(0.6))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(Color.appSurface.opacity(0.9), in: RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
        .accessibilityElement(children: .combine)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
