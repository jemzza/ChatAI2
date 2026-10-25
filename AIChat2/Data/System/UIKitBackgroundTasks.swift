import UIKit

final class UIKitBackgroundTasks: BackgroundTaskScheduling {
    private var nextToken = 0
    private var identifiers: [Int: UIBackgroundTaskIdentifier] = [:]
    
    func beginTask(expiration: @escaping () -> Void) -> Int {
        nextToken += 1
        let token = nextToken
        identifiers[token] = UIApplication.shared.beginBackgroundTask { [weak self] in
            expiration()
            self?.endTask(token)
        }
        return token
    }
    
    func endTask(_ token: Int) {
        guard let identifier = identifiers.removeValue(forKey: token), identifier != .invalid else { return }
        UIApplication.shared.endBackgroundTask(identifier)
    }
}
