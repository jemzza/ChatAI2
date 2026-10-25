import Combine
import Foundation

final class MainViewModel: ObservableObject {
    @Published private(set) var isPremium: Bool
    
    private let subscription: any SubscribableService
    
    init(subscription: any SubscribableService) {
        self.subscription = subscription
        isPremium = subscription.isPremium
    }
    
    var showsProButton: Bool { !isPremium }
    
    func observeSubscription() async {
        for await isPremium in subscription.premiumUpdates() {
            self.isPremium = isPremium
        }
    }
}
