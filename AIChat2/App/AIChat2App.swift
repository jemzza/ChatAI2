import SwiftUI

@main
struct AIChat2App: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var container = AppContainer(
        environment: AppContainer.environment(for: .processInfo),
        launchOptions: LaunchOptions(arguments: ProcessInfo.processInfo.arguments)
    )
    
    var body: some Scene {
        WindowGroup {
            switch container.environment {
                case .live:
                    LiveRoot(container: container)
                case .unitTests:
                    EmptyView()
            }
        }
    }
}
