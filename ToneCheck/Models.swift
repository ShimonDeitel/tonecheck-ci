import Foundation
import SwiftData

// MARK: - Tone category

enum ToneCategory: String, CaseIterable, Codable {
    case confident, aggressive, passive, friendly, formal, casual, neutral

    var label: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .confident: return "bolt.fill"
        case .aggressive: return "exclamationmark.triangle.fill"
        case .passive: return "arrow.down.circle.fill"
        case .friendly: return "hand.wave.fill"
        case .formal: return "briefcase.fill"
        case .casual: return "bubble.left.fill"
        case .neutral: return "minus.circle.fill"
        }
    }
}

// MARK: - ToneResult (used in-memory and for SwiftData history)

struct ToneResult: Codable, Equatable {
    var primaryTone: String
    var subTones: [String]
    var verdict: String
    var rewriteSuggestion: String
    var grade: String   // "A" – "F"
}

// MARK: - SwiftData history entry

@Model
final class HistoryEntry {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var inputText: String = ""
    var primaryTone: String = ""
    var subTonesJSON: String = "[]"
    var verdict: String = ""
    var rewriteSuggestion: String = ""
    var grade: String = "C"

    init(input: String, result: ToneResult) {
        self.id = UUID()
        self.createdAt = .now
        self.inputText = input
        self.primaryTone = result.primaryTone
        self.subTonesJSON = (try? String(data: JSONEncoder().encode(result.subTones), encoding: .utf8)) ?? "[]"
        self.verdict = result.verdict
        self.rewriteSuggestion = result.rewriteSuggestion
        self.grade = result.grade
    }

    var subTones: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(subTonesJSON.utf8))) ?? []
    }

    var toneResult: ToneResult {
        ToneResult(primaryTone: primaryTone, subTones: subTones,
                   verdict: verdict, rewriteSuggestion: rewriteSuggestion, grade: grade)
    }
}

// MARK: - Grade color helper

enum GradeHelper {
    static func color(for grade: String) -> String {
        switch grade.uppercased() {
        case "A": return "gradeA"
        case "B": return "gradeB"
        case "C": return "gradeC"
        case "D": return "gradeD"
        default:  return "gradeF"
        }
    }
}
