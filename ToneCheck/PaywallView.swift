import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var working = false
    @State private var restoreMessage: String?

    private let benefits: [(String, String)] = [
        ("bolt.fill",              "Unlimited tone checks"),
        ("list.bullet.rectangle", "Full tone breakdown"),
        ("clock.arrow.circlepath","Saved history"),
        ("pencil.and.outline",    "Rewrite suggestions")
    ]

    var body: some View {
        ZStack {
            TCBackground()
            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefitList
                    purchaseArea
                    disclosure
                    legalLinks
                }
                .padding(20)
                .padding(.bottom, 32)
            }
            .overlay(alignment: .topTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
        }
    }

    // MARK: Sub-views

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Color.tcAccent)
            Text("ToneCheck Pro")
                .font(.largeTitle.weight(.heavy))
            Text("Check tone, improve communication, save history.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }

    private var benefitList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(benefits, id: \.1) { icon, label in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.tcAccent)
                        .frame(width: 26)
                    Text(label)
                        .font(.body.weight(.medium))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tcCard()
    }

    private var purchaseArea: some View {
        VStack(spacing: 12) {
            Button(action: buy) {
                if working {
                    ProgressView().tint(.white).padding(.vertical, 4)
                } else {
                    Text("Subscribe — \(store.pricePerMonth)")
                }
            }
            .prominentButton()
            .disabled(working || store.purchaseInFlight)

            Button("Restore Purchases") {
                Task {
                    await store.restore()
                    restoreMessage = store.isPro ? "Pro restored." : "No active subscription found."
                    if store.isPro { dismiss() }
                }
            }
            .font(.footnote)
            .foregroundStyle(Color.tcAccent)

            if let msg = restoreMessage {
                Text(msg).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private var disclosure: some View {
        Text("ToneCheck Pro is \(store.pricePerMonth), billed monthly. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store account settings.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 4)
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Text("·").foregroundStyle(.tertiary)
            Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/cool-apps-legal/tonecheck/privacy.html")!)
        }
        .font(.caption.weight(.medium))
        .tint(Color.tcAccent)
    }

    // MARK: Actions

    private func buy() {
        working = true
        Task {
            let ok = await store.purchase()
            working = false
            if ok { Haptics.success(); dismiss() }
        }
    }
}
