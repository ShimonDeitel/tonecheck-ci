import SwiftUI

@main
struct ToneCheckApp: App {
    @StateObject private var store = Store()
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(appModel)
        }
    }
}
