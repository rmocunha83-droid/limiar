import SwiftUI

@main
struct LimiarApp: App {
    @State private var model = LimiarAppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
}
