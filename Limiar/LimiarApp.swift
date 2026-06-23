import SwiftUI

@main
struct LimiarApp: App {
    @State private var model = LimiarAppModel()
    @State private var subscription = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .environment(subscription)
        }
    }
}
