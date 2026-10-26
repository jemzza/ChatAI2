import UserNotifications

final class UserNotificationScheduler: LocalNotificationScheduling {
    private let center = UNUserNotificationCenter.current()
    
    func authorization() async -> NotificationAuthorization {
        switch await center.notificationSettings().authorizationStatus {
            case .authorized, .provisional, .ephemeral: .authorized
            case .denied: .denied
            case .notDetermined: .notDetermined
            @unknown default: .denied
        }
    }
    
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }
    
    func schedule(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }
}
