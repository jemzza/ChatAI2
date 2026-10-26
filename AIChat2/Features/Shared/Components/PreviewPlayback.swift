import AVFoundation
import Combine
import SwiftUI

final class PreviewPlayerPool {
    struct Request {
        let id: AnyHashable
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
        var owner: AnyHashable?
        
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
    
    func player(for id: AnyHashable) -> AVPlayer? {
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

final class PreviewPlaybackController: ObservableObject {
    static let space = "previewPlayback"
    
    @Published private(set) var playingIDs: Set<AnyHashable> = []
    var url: (AnyHashable) -> URL? = { _ in nil }
    var isActive = false {
        didSet { if isActive != oldValue { schedule() } }
    }
    
    private let pool: PreviewPlayerPool
    private var frames: [AnyHashable: CGRect] = [:]
    private var viewport: CGRect = .zero
    private var settleTask: Task<Void, Never>?
    
    init(pool: PreviewPlayerPool = PreviewPlayerPool()) {
        self.pool = pool
    }
    
    deinit {
        settleTask?.cancel()
    }
    
    func player(for id: AnyHashable) -> AVPlayer? {
        playingIDs.contains(id) ? pool.player(for: id) : nil
    }
    
    func update(frames: [AnyHashable: CGRect]) {
        self.frames = frames
        schedule()
    }
    
    func update(viewport size: CGSize) {
        viewport = CGRect(origin: .zero, size: size)
        schedule()
    }
    
    func stop() {
        settleTask?.cancel()
        pool.stopAll()
        if !playingIDs.isEmpty { playingIDs = [] }
    }
    
    private func schedule() {
        settleTask?.cancel()
        guard isActive, !ProcessInfo.processInfo.isLowPowerModeEnabled else {
            if !playingIDs.isEmpty { playingIDs = [] }
            return
        }
        settleTask = Task { [weak self] in
            guard (try? await Task.sleep(for: .milliseconds(300))) != nil, let self else { return }
            let requests = visibleRequests()
            pool.play(requests)
            let ids = Set(requests.prefix(pool.capacity).map(\.id))
            if ids != playingIDs { playingIDs = ids }
        }
    }
    
    private func visibleRequests() -> [PreviewPlayerPool.Request] {
        frames
            .filter { _, frame in
                let visible = frame.intersection(viewport)
                return !visible.isNull && visible.width * visible.height >= frame.width * frame.height * 0.6
            }
            .sorted { lhs, rhs in
                lhs.value.minY == rhs.value.minY ? lhs.value.minX < rhs.value.minX : lhs.value.minY < rhs.value.minY
            }
            .compactMap { id, _ in url(id).map { PreviewPlayerPool.Request(id: id, url: $0) } }
    }
}

private struct PreviewFramesKey: PreferenceKey {
    static let defaultValue: [AnyHashable: CGRect] = [:]
    
    static func reduce(value: inout [AnyHashable: CGRect], nextValue: () -> [AnyHashable: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func previewFrame(id: some Hashable) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: PreviewFramesKey.self,
                    value: [AnyHashable(id): proxy.frame(in: .named(PreviewPlaybackController.space))]
                )
            }
        }
    }
    
    func previewPlayback(_ controller: PreviewPlaybackController) -> some View {
        coordinateSpace(name: PreviewPlaybackController.space)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { controller.update(viewport: proxy.size) }
                        .onChange(of: proxy.size) { controller.update(viewport: $0) }
                }
            }
            .onPreferenceChange(PreviewFramesKey.self) { controller.update(frames: $0) }
    }
}

struct PreviewVideoLayer: View {
    let player: AVPlayer?
    @State private var isReady = false
    
    var body: some View {
        ZStack {
            if let player {
                PlayerLayerView(player: player) { isReady = $0 }
                    .opacity(isReady ? 1 : 0)
                    .animation(.easeOut(duration: 0.25), value: isReady)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: player == nil) { isEmpty in
            if isEmpty { isReady = false }
        }
    }
}
