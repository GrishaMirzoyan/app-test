import SwiftUI

@main
struct LexiconLockApp: App {
    @StateObject private var services = AppServices()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(services)
        }
    }
}
