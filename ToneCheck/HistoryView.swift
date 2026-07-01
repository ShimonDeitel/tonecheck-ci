import SwiftUI
import SwiftData

struct HistoryView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Query(sort: \HistoryEntry.createdAt, order: .reverse) private var entries: [HistoryEntry]

    @State private var showPaywall = false
    @State private var selected: HistoryEntry?

    var body: some View {
        NavigationStack {
            ZStack {
                TCBackground()
                if !store.isPro {
                    paywallGate
                } else if entries.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(item: $selected) { entry in
                entryDetail(entry: entry)
            }
        }
    }

    // MARK: Sub-views

    private var list: some View {
        List {
            ForEach(entries) { entry in
                Button { selected = entry } label: {
                    HStack(spacing: 12) {
                        GradeBadge(grade: entry.grade)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.primaryTone)
                                .font(.headline)
                            Text(entry.inputText.prefix(60) + (entry.inputText.count > 60 ? "..." : ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(entry.createdAt, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.tcCard)
            }
            .onDelete { indexSet in
                for i in indexSet { appModel.deleteEntry(entries[i]) }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No history yet")
                .font(.title3.weight(.semibold))
            Text("After a tone check, tap Save to add it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var paywallGate: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.tcAccent)
            Text("Saved History")
                .font(.title2.weight(.bold))
            Text("Upgrade to Pro to save tone checks and access them later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Upgrade to Pro") { showPaywall = true }
                .prominentButton()
                .frame(maxWidth: 240)
        }
        .padding(32)
    }

    private func entryDetail(entry: HistoryEntry) -> some View {
        NavigationStack {
            ZStack {
                TCBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Original Text")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text(entry.inputText)
                                .font(.body)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.tcCard2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        ToneResultView(result: entry.toneResult, isPro: true)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(entry.primaryTone)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
