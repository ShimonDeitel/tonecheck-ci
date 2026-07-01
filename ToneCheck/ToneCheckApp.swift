import SwiftUI

@main
struct ToneCheckApp: App {
    @StateObject private var store = Store()
    @StateObject private var appModel = AppModel()
    @StateObject private var account = AccountManager()

    init() {}

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(appModel)
                .environmentObject(account)
                .onAppear {
                    // Wire the store reference so AppModel can check Pro status
                    appModel.store = store
                }
        }
    }
}
