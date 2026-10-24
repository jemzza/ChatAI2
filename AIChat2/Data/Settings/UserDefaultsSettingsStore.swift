//
//  UserDefaultsSettingsStore.swift
//  AIChat2
//

import Combine
import Foundation

@MainActor
final class UserDefaultsSettingsStore: SettingsStorable, ObservableObject {
    private enum Key {
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
        static let notifyOnReply = "settings.notifyOnReply"
        static let notifyOnQueuedSent = "settings.notifyOnQueuedSent"
    }
    
    private let defaults: UserDefaults
    
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) }
    }
    
    @Published var notifyOnReply: Bool {
        didSet { defaults.set(notifyOnReply, forKey: Key.notifyOnReply) }
    }
    
    @Published var notifyOnQueuedSent: Bool {
        didSet { defaults.set(notifyOnQueuedSent, forKey: Key.notifyOnQueuedSent) }
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
        notifyOnReply = defaults.bool(forKey: Key.notifyOnReply)
        notifyOnQueuedSent = defaults.bool(forKey: Key.notifyOnQueuedSent)
    }
}
