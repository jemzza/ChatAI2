//
//  SettingsStorable.swift
//  AIChat2
//

import Foundation

@MainActor
protocol SettingsStorable: AnyObject {
    var hasCompletedOnboarding: Bool { get set }
    var notifyOnReply: Bool { get set }
    var notifyOnQueuedSent: Bool { get set }
}
