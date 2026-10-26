import Combine
import Foundation

final class SettingsViewModel: ObservableObject {
    enum Alert: Identifiable, Equatable {
        case notificationsDenied
        case restored
        case nothingToRestore
        case restoreFailed
        
        var id: Self { self }
    }
    
    @Published private(set) var notificationsEnabled: Bool
    @Published private(set) var cacheSize: Int64?
    @Published private(set) var isRestoring = false
    @Published private(set) var isPremium: Bool
    @Published var alert: Alert?
    
    private let settings: any SettingsStorable
    private let scheduler: any LocalNotificationScheduling
    private let cache: any CacheManaging
    private let subscription: any SubscribableService
    
    init(
        settings: any SettingsStorable,
        scheduler: any LocalNotificationScheduling,
        cache: any CacheManaging,
        subscription: any SubscribableService
    ) {
        self.settings = settings
        self.scheduler = scheduler
        self.cache = cache
        self.subscription = subscription
        notificationsEnabled = settings.notifyOnReply
        isPremium = subscription.isPremium
    }
    
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    func load() async {
        cacheSize = await cache.size()
        if notificationsEnabled, await scheduler.authorization() == .denied {
            setNotifications(false)
        }
    }
    
    func observeSubscription() async {
        for await isPremium in subscription.premiumUpdates() {
            self.isPremium = isPremium
        }
    }
    
    func toggleNotifications(_ isOn: Bool) async {
        guard isOn else {
            setNotifications(false)
            return
        }
        switch await scheduler.authorization() {
            case .authorized:
                setNotifications(true)
            case .notDetermined:
                setNotifications(await scheduler.requestAuthorization())
            case .denied:
                setNotifications(false)
                alert = .notificationsDenied
        }
    }
    
    func clearCache() async {
        await cache.clear()
        cacheSize = await cache.size()
    }
    
    func restore() async {
        guard !isRestoring else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            alert = try await subscription.restore() ? .restored : .nothingToRestore
        } catch {
            alert = .restoreFailed
        }
    }
    
    private func setNotifications(_ isOn: Bool) {
        notificationsEnabled = isOn
        settings.notifyOnReply = isOn
        settings.notifyOnQueuedSent = isOn
    }
}
