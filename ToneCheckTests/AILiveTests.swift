import XCTest
@testable import ToneCheck

/// Live network test: calls AIClient with a real text and asserts we get a valid ToneResult.
/// Skipped automatically when there is no API key or the network is unavailable.
final class AILiveTests: XCTestCase {

    func testLiveAnalyzeToneReturnsResult() async throws {
        let text = "I need you to send that report IMMEDIATELY. This is completely unacceptable."
        let result: ToneResult
        do {
            result = try await AIClient.shared.analyzeTone(text: text)
        } catch {
            throw XCTSkip("Live AI call failed (network/key/limit): \(error.localizedDescription)")
        }

        print("Primary tone: \(result.primaryTone)")
        print("Grade: \(result.grade)")
        print("SubTones: \(result.subTones)")
        print("Verdict: \(result.verdict)")

        XCTAssertFalse(result.primaryTone.isEmpty, "Expected a primary tone")
        XCTAssertFalse(result.grade.isEmpty, "Expected a grade")
        XCTAssertFalse(result.verdict.isEmpty, "Expected a verdict")
        XCTAssertFalse(result.rewriteSuggestion.isEmpty, "Expected a rewrite suggestion")
        XCTAssertTrue(["A","B","C","D","F"].contains(result.grade.uppercased()), "Grade should be A-F")
    }
}
