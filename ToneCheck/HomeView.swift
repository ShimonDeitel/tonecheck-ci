import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @EnvironmentObject var account: AccountManager

    @State private var inputText = ""
    @State private var showPaywall = false
    @State private var showSettings = false
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        ZStack {
            ToneCheckBackground()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    inputSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    checkButton
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    resultSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ToneCheck")
                    .font(.title2.weight(.bold))
                if !store.isPro {
                    Text("\(appModel.analysesRemaining) free \(appModel.analysesRemaining == 1 ? "check" : "checks") left today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paste or type your message")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.tonecheckField)
                    .frame(minHeight: 140)

                if inputText.isEmpty {
                    Text("e.g. \"Fine. Do whatever you want.\"")
                        .font(.body)
                        .foregroundStyle(Color(uiColor: .placeholderText))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $inputText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 140)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .focused($textFieldFocused)
            }

            if !inputText.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        inputText = ""
                        appModel.reset()
                        Haptics.tap()
                    } label: {
                        Text("Clear")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Check Button

    private var checkButton: some View {
        Button {
            handleCheckTone()
        } label: {
            HStack(spacing: 8) {
                if case .analyzing = appModel.analysisState {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "waveform.badge.magnifyingglass")
                }
                Text(buttonLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .prominentButton()
        .disabled(isCheckDisabled)
        .animation(.easeInOut(duration: 0.2), value: appModel.analysisState == .analyzing)
    }

    private var buttonLabel: String {
        if case .analyzing = appModel.analysisState { return "Analyzing..." }
        return "Check Tone"
    }

    private var isCheckDisabled: Bool {
        if case .analyzing = appModel.analysisState { return true }
        return inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleCheckTone() {
        textFieldFocused = false
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if !appModel.canAnalyze {
            showPaywall = true
            return
        }

        Haptics.tap()
        Task { await appModel.analyze(text: inputText) }
    }

    // MARK: - Result

    @ViewBuilder
    private var resultSection: some View {
        switch appModel.analysisState {
        case .idle:
            EmptyView()
        case .analyzing:
            AnalyzingCard()
        case .result(let result):
            ResultCard(result: result, originalText: inputText)
        case .error(let msg):
            ErrorCard(message: msg)
        }
    }
}

// MARK: - Analyzing placeholder

struct AnalyzingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Reading between the lines...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .tonecheckCard()
    }
}

// MARK: - Result Card

struct ResultCard: View {
    let result: ToneResult
    let originalText: String

    @EnvironmentObject var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Verdict badge
            HStack(spacing: 10) {
                Image(systemName: result.verdict.sfSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(verdictColor)
                Text(result.verdict.rawValue)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(verdictColor)
                Spacer()
                Text("\(result.score)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(verdictColor)
            }

            // Score bar
            VStack(alignment: .leading, spacing: 6) {
                Text("Aggression Score")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(uiColor: .systemFill))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(verdictColor)
                            .frame(width: geo.size.width * CGFloat(result.score) / 100.0, height: 8)
                            .animation(.spring(duration: 0.6), value: result.score)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("Calm")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Intense")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Trigger phrases
            VStack(alignment: .leading, spacing: 8) {
                Text("What triggered it")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                ForEach(result.triggers, id: \.self) { phrase in
                    HStack(spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.caption2)
                            .foregroundStyle(Color.tonecheckAccent)
                        Text(phrase)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
            }

            // Rewrite section
            Divider()

            if let rewritten = appModel.rewriteResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested rewrite")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(rewritten)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(12)
                        .background(Color.tonecheckField, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else {
                Button {
                    Haptics.tap()
                    Task { await appModel.rewrite(text: originalText) }
                } label: {
                    HStack(spacing: 6) {
                        if appModel.isRewriting {
                            ProgressView().tint(Color.tonecheckAccent)
                        } else {
                            Image(systemName: "pencil.and.sparkles")
                        }
                        Text(appModel.isRewriting ? "Rewriting..." : "Rewrite it")
                    }
                    .frame(maxWidth: .infinity)
                }
                .softButton()
                .disabled(appModel.isRewriting)
            }
        }
        .tonecheckCard()
    }

    private var verdictColor: Color {
        switch result.verdict.color {
        case "danger":  return Color(uiColor: .systemRed)
        case "caution": return Color(uiColor: .systemOrange)
        default:        return Color(uiColor: .systemGreen)
        }
    }
}

// MARK: - Error Card

struct ErrorCard: View {
    let message: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color(uiColor: .systemRed))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tonecheckCard()
    }
}
