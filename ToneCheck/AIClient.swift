import Foundation

// MARK: - Errors

enum AIError: Error, LocalizedError {
    case noAPIKey
    case badResponse
    case http(Int)
    case decoding(String)
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .noAPIKey:       return "No API key configured."
        case .badResponse:    return "No response from the service."
        case .http(let code): return "Service returned \(code)."
        case .decoding(let d):return "Couldn't read the result: \(d)"
        case .rateLimited:    return "Daily limit reached — resets tomorrow."
        }
    }
}

// MARK: - OpenRouter wire envelope

private struct ORRequest: Encodable {
    struct Message: Encodable { let role: String; let content: String }
    let model: String
    let messages: [Message]
    let max_tokens: Int
    let temperature: Double
}

private struct ORResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String? }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - AIClient

final class AIClient {
    static let shared = AIClient()
    private init() {}

    private let systemPrompt = """
You are a communication-tone expert. Analyze the tone of the user's text and respond with ONLY valid JSON — no explanation, no markdown, no code fences.

JSON schema (all fields required):
{
  "primaryTone": "<one of: Confident, Aggressive, Passive, Friendly, Formal, Casual, Neutral>",
  "subTones": ["<sub-tone 1>", "<sub-tone 2>"],
  "verdict": "<1-2 sentence plain-English summary of the tone and its likely impact on the reader>",
  "rewriteSuggestion": "<a single, improved rewrite of the input that keeps the same intent but improves the tone>",
  "grade": "<A, B, C, D, or F — A = excellent tone, F = likely to cause friction>"
}

Rules:
- subTones: 1-4 descriptive words or short phrases (e.g. "assertive", "slightly dismissive")
- grade criteria: A = warm + clear, B = mostly good minor issues, C = neutral, D = likely to land poorly, F = hostile or passive-aggressive
- Keep rewriteSuggestion under 100 words
- Do NOT include any text outside the JSON object
"""

    func analyzeTone(text: String) async throws -> ToneResult {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        let session = URLSession(configuration: cfg)

        var request = URLRequest(url: AIConfig.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !AIConfig.apiKey.isEmpty {
            request.setValue("Bearer \(AIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("https://tonecheck.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("ToneCheck", forHTTPHeaderField: "X-Title")

        let body = ORRequest(
            model: AIConfig.model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: text)
            ],
            max_tokens: 512,
            temperature: 0.2
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIError.badResponse
        }

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 429 { throw AIError.rateLimited }
            guard (200..<300).contains(http.statusCode) else { throw AIError.http(http.statusCode) }
        }

        let envelope: ORResponse
        do { envelope = try JSONDecoder().decode(ORResponse.self, from: data) }
        catch { throw AIError.decoding("envelope: \(error)") }

        guard let content = envelope.choices.first?.message.content, !content.isEmpty else {
            throw AIError.badResponse
        }

        // Strip potential markdown fences
        let cleaned = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to extract JSON object
        for candidate in jsonCandidates(from: cleaned) {
            if let jsonData = candidate.data(using: .utf8),
               let result = try? JSONDecoder().decode(ToneResult.self, from: jsonData) {
                return result
            }
        }
        throw AIError.decoding("no valid JSON in: \(cleaned.prefix(200))")
    }

    private func jsonCandidates(from content: String) -> [String] {
        var out = [content]
        if let open = content.firstIndex(of: "{"), let close = content.lastIndex(of: "}"), open <= close {
            out.append(String(content[open...close]))
        }
        return out
    }
}
