import SwiftUI
@preconcurrency import GoogleMobileAds

@main
struct LimiarApp: App {
    @State private var model = LimiarAppModel()
    @State private var subscription = SubscriptionManager()

    init() {
        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
        MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .environment(subscription)
        }
    }
}
