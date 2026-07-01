import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel

    @State private var selection: Tab = .check

    enum Tab: Hashable { case check, history }

    var body: some View {
        TabView(selection: $selection) {
            CheckView()
                .tabItem { Label("Check", systemImage: "text.magnifyingglass") }
                .tag(Tab.check)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)
        }
        .tint(Color.tcAccent)
    }
}
