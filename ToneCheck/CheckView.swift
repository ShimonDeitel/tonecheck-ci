import SwiftUI

struct CheckView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel

    @State private var showPaywall = false
    @State private var savedConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                TCBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ToneCheck")
                                .font(.largeTitle.weight(.heavy))
                            Text("Analyze the tone of any message before you send it.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Free tier counter
                        if !store.isPro {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(Color.tcAccent)
                                Text("\(appModel.remainingFreeChecks) free check\(appModel.remainingFreeChecks == 1 ? "" : "s") remaining today")
                                    .font(.footnote.weight(.medium))
                                Spacer()
                                Button("Go Pro") { showPaywall = true }
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color.tcAccent)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.tcCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // Text editor
                        ZStack(alignment: .topLeading) {
                            if appModel.inputText.isEmpty {
                                Text("Paste your text here...")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            TextEditor(text: $appModel.inputText)
                                .frame(minHeight: 140)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(12)
                        .background(Color.tcField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .font(.body)

                        // Analyze button
                        Button {
                            guard !appModel.isLoading else { return }
                            Haptics.tap()
                            if appModel.canCheck(isPro: store.isPro) {
                                Task { await appModel.analyzeText(isPro: store.isPro) }
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            if appModel.isLoading {
                                ProgressView().tint(.white)
                                    .padding(.vertical, 4)
                            } else {
                                Text("Check Tone")
                            }
                        }
                        .prominentButton()
                        .disabled(appModel.isLoading || appModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        // Error
                        if let err = appModel.error {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(.red)
                                Text(err)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.tcCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // Result
                        if let result = appModel.result {
                            ToneResultView(
                                result: result,
                                isPro: store.isPro,
                                onSave: {
                                    appModel.saveToHistory(result: result, input: appModel.inputText)
                                    Haptics.success()
                                    savedConfirmation = true
                                },
                                onUpgrade: { showPaywall = true }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        if savedConfirmation {
                            Label("Saved to history", systemImage: "checkmark.circle.fill")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(Color.tcAccent)
                                .transition(.opacity)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                    .animation(.spring(response: 0.45), value: appModel.result == nil)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: appModel.result) { _, _ in savedConfirmation = false }
        }
    }
}
