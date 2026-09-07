import SwiftUI

@main
struct OmiDevApp: App {
    @State private var store = SeedStore()

    var body: some Scene {
        WindowGroup {
            RootShell()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}
