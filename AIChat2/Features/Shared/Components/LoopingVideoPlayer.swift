import AVFoundation
import SwiftUI
import UIKit

struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL
    var isPlaying = true
    var isMuted = true
    var gravity: AVLayerVideoGravity = .resizeAspectFill
    
    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.configure(url: url, gravity: gravity)
        return view
    }
    
    func updateUIView(_ view: PlayerView, context: Context) {
        if view.url != url { view.configure(url: url, gravity: gravity) }
        view.player.isMuted = isMuted
        if isPlaying { view.player.play() } else { view.player.pause() }
    }
    
    static func dismantleUIView(_ view: PlayerView, coordinator: ()) {
        view.stop()
    }
    
    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        
        let player = AVQueuePlayer()
        private(set) var url: URL?
        private var looper: AVPlayerLooper?
        
        func configure(url: URL, gravity: AVLayerVideoGravity) {
            self.url = url
            guard let playerLayer = layer as? AVPlayerLayer else { return }
            playerLayer.player = player
            playerLayer.videoGravity = gravity
            stop()
            looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        }
        
        func stop() {
            looper?.disableLooping()
            looper = nil
            player.pause()
            player.removeAllItems()
        }
    }
}
