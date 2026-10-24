//
//  SettingsStorable.swift
//  AIChat2
//

import Foundation

/// Настройки пользователя. Хранятся вне базы (`UserDefaults`):
@MainActor
protocol SettingsStorable: AnyObject {
    /// Онбординг пройден — дальше запуск сразу с главного экрана.
    var hasCompletedOnboarding: Bool { get set }
    /// Уведомлять о готовом ответе, пока приложение не активно.
    var notifyOnReply: Bool { get set }
    /// Уведомлять, когда outbox отправил сообщения, ждавшие сети.
    var notifyOnQueuedSent: Bool { get set }
}
