import Foundation

enum NotificationAuthorization {
    case authorized
    case denied
    case notDetermined
}

protocol LocalNotificationScheduling: AnyObject {
    func authorization() async -> NotificationAuthorization
    func requestAuthorization() async -> Bool
    func schedule(title: String, body: String) async
}

protocol ActivityNotifying: AnyObject {
    func replyDidFinish(text: String) async
    func videoDidFinish(templateName: String) async
}
