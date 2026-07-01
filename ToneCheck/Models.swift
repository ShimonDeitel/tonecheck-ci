import Foundation

// MARK: - Tone Result

enum ToneVerdict: String, Codable {
    case passiveAggressive = "Passive-Aggressive"
    case neutral           = "Neutral"
    case cold              = "Cold"
    case clingy            = "Clingy"
    case direct            = "Direct"

    var color: String {
        switch self {
        case .passiveAggressive: return "danger"
        case .cold:              return "caution"
        case .clingy:            return "caution"
        case .neutral:           return "ok"
        case .direct:            return "ok"
        }
    }

    var sfSymbol: String {
        switch self {
        case .passiveAggressive: return "exclamationmark.triangle.fill"
        case .cold:              return "snowflake"
        case .clingy:            return "person.fill.checkmark"
        case .neutral:           return "checkmark.circle.fill"
        case .direct:            return "arrow.right.circle.fill"
        }
    }
}

struct ToneResult: Identifiable {
    let id = UUID()
    let verdict: ToneVerdict
    let score: Int          // 0-100 aggression score
    let triggers: [String]  // 1-2 phrases that triggered the verdict
    let rewrite: String?    // softened version (nil until requested)
    let originalText: String
}

// MARK: - Analysis State

enum AnalysisState: Equatable {
    case idle
    case analyzing
    case result(ToneResult)
    case error(String)

    static func == (lhs: AnalysisState, rhs: AnalysisState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.analyzing, .analyzing): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - OpenRouter Response DTOs

struct OpenRouterRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct OpenRouterResponse: Decodable {
    let choices: [Choice]
    struct Choice: Decodable {
        let message: ChatMessage
    }
}

struct ToneAnalysisDTO: Decodable {
    let verdict: String
    let score: Int
    let triggers: [String]
}
