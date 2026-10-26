import Foundation

final class NotificationService: ActivityNotifying {
    private let settings: any SettingsStorable
    private let scheduler: any LocalNotificationScheduling
    private let isAppActive: () -> Bool
    
    init(
        settings: any SettingsStorable,
        scheduler: any LocalNotificationScheduling,
        isAppActive: @escaping () -> Bool
    ) {
        self.settings = settings
        self.scheduler = scheduler
        self.isAppActive = isAppActive
    }
    
    func replyDidFinish(text: String) async {
        guard settings.notifyOnReply, !isAppActive() else { return }
        await scheduler.schedule(
            title: String(localized: "Your answer is ready"),
            body: MarkdownParser.plainText(text)
        )
    }
    
    func videoDidFinish(templateName: String) async {
        guard settings.notifyOnReply, !isAppActive() else { return }
        await scheduler.schedule(title: String(localized: "Your video is ready"), body: templateName)
    }
}
