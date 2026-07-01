import Foundation
import SwiftUI
import SwiftData

@MainActor
final class AppModel: ObservableObject {
    // MARK: - Published state

    @Published var inputText: String = ""
    @Published private(set) var result: ToneResult?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: String?

    // MARK: - Free tier

    /// Free users get 5 checks per calendar day.
    static let freeDailyLimit = 5

    private let kCheckCountKey = "tonecheck.free.count"
    private let kCheckDayKey = "tonecheck.free.day"

    private var todayKey: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func rollIfNeeded() {
        let d = UserDefaults.standard
        if d.string(forKey: kCheckDayKey) != todayKey {
            d.set(todayKey, forKey: kCheckDayKey)
            d.set(0, forKey: kCheckCountKey)
        }
    }

    var dailyCheckCount: Int {
        rollIfNeeded()
        return UserDefaults.standard.integer(forKey: kCheckCountKey)
    }

    var remainingFreeChecks: Int {
        max(0, Self.freeDailyLimit - dailyCheckCount)
    }

    func canCheck(isPro: Bool) -> Bool {
        if isPro { return true }
        rollIfNeeded()
        return dailyCheckCount < Self.freeDailyLimit
    }

    private func recordCheck() {
        rollIfNeeded()
        let d = UserDefaults.standard
        d.set(d.integer(forKey: kCheckCountKey) + 1, forKey: kCheckCountKey)
    }

    // MARK: - SwiftData container (local only)

    let container: ModelContainer

    static func makeContainer() -> ModelContainer {
        let schema = Schema([HistoryEntry.self])
        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        if let c = try? ModelContainer(for: schema, configurations: local) { return c }
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: mem)
    }

    init() {
        self.container = Self.makeContainer()
    }

    var context: ModelContext { container.mainContext }

    // MARK: - Analyze

    func analyzeText(isPro: Bool) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            error = "Paste some text first."
            return
        }
        guard canCheck(isPro: isPro) else {
            error = "You've used your 5 free checks today. Upgrade to Pro for unlimited checks."
            return
        }

        isLoading = true
        error = nil
        result = nil

        do {
            let r = try await AIClient.shared.analyzeTone(text: text)
            result = r
            recordCheck()
        } catch AIError.rateLimited {
            error = "Daily limit reached — resets tomorrow."
        } catch AIError.badResponse {
            error = "Couldn't reach the service. Check your connection and try again."
        } catch AIError.http(let code) {
            if AIConfig.apiKey.isEmpty {
                error = "No API key configured. Add your OpenRouter key to AIConfig.swift."
            } else {
                error = "Service error (\(code)). Please try again."
            }
        } catch {
            self.error = "Something went wrong. Please try again."
        }

        isLoading = false
    }

    // MARK: - Save to history (Pro)

    func saveToHistory(result: ToneResult, input: String) {
        let entry = HistoryEntry(input: input, result: result)
        context.insert(entry)
        try? context.save()
    }

    func deleteEntry(_ entry: HistoryEntry) {
        context.delete(entry)
        try? context.save()
    }

    func clearResult() {
        result = nil
        error = nil
    }
}
