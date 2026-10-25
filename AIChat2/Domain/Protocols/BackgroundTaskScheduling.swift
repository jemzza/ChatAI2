import Foundation

protocol BackgroundTaskScheduling: AnyObject {
    func beginTask(expiration: @escaping () -> Void) -> Int
    func endTask(_ token: Int)
}
