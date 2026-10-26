import AVFoundation

final class PreviewPlayerPool {
    struct Request: Hashable {
        let id: Int64
        let url: URL
    }
    
    private final class Slot {
        let player: AVQueuePlayer = {
            let player = AVQueuePlayer()
            player.isMuted = true
            player.preventsDisplaySleepDuringVideoPlayback = false
            return player
        }()
        var looper: AVPlayerLooper?
        var owner: Int64?
        
        func load(_ request: Request) {
            reset()
            owner = request.id
            let item = AVPlayerItem(url: request.url)
            item.preferredForwardBufferDuration = 2
            looper = AVPlayerLooper(player: player, templateItem: item)
            player.play()
        }
        
        func reset() {
            looper?.disableLooping()
            looper = nil
            player.pause()
            player.removeAllItems()
            owner = nil
        }
    }
    
    let capacity: Int
    private var slots: [Slot] = []
    
    init(capacity: Int = 4) {
        self.capacity = capacity
    }
    
    deinit {
        slots.forEach { $0.reset() }
    }
    
    func player(for id: Int64) -> AVPlayer? {
        slots.first { $0.owner == id }?.player
    }
    
    func play(_ requests: [Request]) {
        if slots.isEmpty { slots = (0..<capacity).map { _ in Slot() } }
        let wanted = Array(requests.prefix(capacity))
        let wantedIDs = Set(wanted.map(\.id))
        for slot in slots where slot.owner.map({ !wantedIDs.contains($0) }) ?? false {
            slot.reset()
        }
        for request in wanted where !slots.contains(where: { $0.owner == request.id }) {
            slots.first { $0.owner == nil }?.load(request)
        }
    }
    
    func stopAll() {
        slots.forEach { $0.reset() }
    }
}
