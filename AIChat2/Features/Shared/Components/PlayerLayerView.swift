import AVFoundation
import SwiftUI
import UIKit

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    var onReady: (Bool) -> Void = { _ in }
    
    func makeUIView(context: Context) -> LayerView {
        let view = LayerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.onReady = onReady
        view.attach(player)
        return view
    }
    
    func updateUIView(_ view: LayerView, context: Context) {
        view.onReady = onReady
        if view.playerLayer.player !== player { view.attach(player) }
    }
    
    static func dismantleUIView(_ view: LayerView, coordinator: ()) {
        view.detach()
    }
    
    final class LayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        var onReady: (Bool) -> Void = { _ in }
        private var readyObservation: NSKeyValueObservation?
        
        func attach(_ player: AVPlayer) {
            readyObservation?.invalidate()
            playerLayer.player = player
            readyObservation = playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] layer, _ in
                let isReady = layer.isReadyForDisplay
                DispatchQueue.main.async { self?.onReady(isReady) }
            }
        }
        
        func detach() {
            readyObservation?.invalidate()
            readyObservation = nil
            playerLayer.player = nil
        }
    }
}
