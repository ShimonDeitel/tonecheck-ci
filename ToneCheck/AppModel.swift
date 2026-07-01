import Foundation
import SwiftUI

// MARK: - Usage tracking (free tier: 5 analyses/day)

@MainActor
final class AppModel: ObservableObject {
    weak var store: Store?

    @Published var analysisState: AnalysisState = .idle
    @Published var rewriteResult: String? = nil
    @Published var isRewriting = false

    private let kUsageDate  = "tonecheck.usage.date"
    private let kUsageCount = "tonecheck.usage.count"

    static let freeLimit = 5
    private let apiKey   = "sk-or-placeholder"
    private let model    = "openai/gpt-4o-mini"

    // MARK: Daily usage

    var usageToday: Int {
        guard let stored = UserDefaults.standard.string(forKey: kUsageDate),
              stored == todayKey else { return 0 }
        return UserDefaults.standard.integer(forKey: kUsageCount)
    }

    var canAnalyze: Bool {
        store?.isPro == true || usageToday < Self.freeLimit
    }

    var analysesRemaining: Int {
        max(0, Self.freeLimit - usageToday)
    }

    private var todayKey: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func incrementUsage() {
        let key = todayKey
        if UserDefaults.standard.string(forKey: kUsageDate) != key {
            UserDefaults.standard.set(key, forKey: kUsageDate)
            UserDefaults.standard.set(0, forKey: kUsageCount)
        }
        let n = UserDefaults.standard.integer(forKey: kUsageCount) + 1
        UserDefaults.standard.set(n, forKey: kUsageCount)
    }

    // MARK: Tone Analysis

    func analyze(text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        analysisState = .analyzing
        rewriteResult = nil

        do {
            let result = try await callOpenRouter(for: text)
            incrementUsage()
            analysisState = .result(result)
            Haptics.success()
        } catch {
            analysisState = .error(error.localizedDescription)
        }
    }

    func rewrite(text: String) async {
        isRewriting = true
        do {
            let rewritten = try await callRewrite(for: text)
            rewriteResult = rewritten
        } catch {
            rewriteResult = nil
        }
        isRewriting = false
    }

    func reset() {
        analysisState = .idle
        rewriteResult = nil
    }

    // MARK: Private: API calls

    private func callOpenRouter(for text: String) async throws -> ToneResult {
        let systemPrompt = """
        You are a message tone analyzer. Analyze the tone of a text message and return JSON only.
        Return exactly this JSON structure with no other text:
        {
          "verdict": "<one of: Passive-Aggressive, Neutral, Cold, Clingy, Direct>",
          "score": <integer 0-100 representing aggression/tension level>,
          "triggers": ["<phrase 1>", "<phrase 2 if applicable>"]
        }
        Guidelines:
        - score 0-30: calm and fine
        - score 31-60: some tension, use caution
        - score 61-100: high tension or problematic tone
        - triggers: 1-2 specific short phrases from the text that most signal the tone
        - triggers array must have at least 1 element
        """

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: "Analyze this message:\n\n\(text)")
        ]

        let responseText = try await post(messages: messages, maxTokens: 200)

        // Parse JSON from response
        let cleaned = responseText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "```json").last?
            .components(separatedBy: "```").first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? responseText

        guard let data = cleaned.data(using: .utf8),
              let dto = try? JSONDecoder().decode(ToneAnalysisDTO.self, from: data) else {
            throw ToneError.parseFailure
        }

        let verdict = ToneVerdict(rawValue: dto.verdict) ?? .neutral
        let score   = max(0, min(100, dto.score))
        let triggers = Array(dto.triggers.prefix(2))

        return ToneResult(verdict: verdict, score: score, triggers: triggers,
                          rewrite: nil, originalText: text)
    }

    private func callRewrite(for text: String) async throws -> String {
        let messages = [
            ChatMessage(role: "system", content: "You are a communication coach. Rewrite the following message to be more neutral, warm, and direct. Return only the rewritten message with no preamble or explanation."),
            ChatMessage(role: "user", content: text)
        ]
        return try await post(messages: messages, maxTokens: 300)
    }

    private func post(messages: [ChatMessage], maxTokens: Int) async throws -> String {
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ToneCheck iOS", forHTTPHeaderField: "X-Title")

        let body = OpenRouterRequest(model: model, messages: messages,
                                     temperature: 0.3, max_tokens: maxTokens)
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 30

        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ToneError.apiError(msg)
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw ToneError.emptyResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ToneError: LocalizedError {
    case parseFailure
    case emptyResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .parseFailure:    return "Could not parse tone result. Please try again."
        case .emptyResponse:   return "No response from server. Please try again."
        case .apiError(let m): return "API error: \(m)"
        }
    }
}
