import XCTest
@testable import ToneCheck

final class ToneCheckTests: XCTestCase {

    // MARK: ToneResult JSON decoding

    func testToneResultDecodesCanonical() throws {
        let json = """
        {
          "primaryTone": "Aggressive",
          "subTones": ["harsh", "urgent"],
          "verdict": "This message may come across as demanding.",
          "rewriteSuggestion": "Could you please send the report when you have a chance?",
          "grade": "D"
        }
        """.data(using: .utf8)!
        let r = try JSONDecoder().decode(ToneResult.self, from: json)
        XCTAssertEqual(r.primaryTone, "Aggressive")
        XCTAssertEqual(r.subTones, ["harsh", "urgent"])
        XCTAssertEqual(r.grade, "D")
        XCTAssertFalse(r.verdict.isEmpty)
        XCTAssertFalse(r.rewriteSuggestion.isEmpty)
    }

    func testToneResultDecodesMissingSubTonesGracefully() throws {
        let json = """
        {
          "primaryTone": "Friendly",
          "subTones": [],
          "verdict": "Warm and approachable.",
          "rewriteSuggestion": "This is already great!",
          "grade": "A"
        }
        """.data(using: .utf8)!
        let r = try JSONDecoder().decode(ToneResult.self, from: json)
        XCTAssertTrue(r.subTones.isEmpty)
        XCTAssertEqual(r.grade, "A")
    }

    // MARK: HistoryEntry round-trip

    func testHistoryEntryRoundTrip() {
        let result = ToneResult(primaryTone: "Formal", subTones: ["polite", "distant"], verdict: "Sounds professional.", rewriteSuggestion: "As discussed, please find…", grade: "B")
        let entry = HistoryEntry(input: "Per our conversation, I need this done.", result: result)
        let rt = entry.toneResult
        XCTAssertEqual(rt.primaryTone, result.primaryTone)
        XCTAssertEqual(rt.subTones, result.subTones)
        XCTAssertEqual(rt.grade, result.grade)
        XCTAssertEqual(rt.verdict, result.verdict)
    }

    // MARK: ToneCategory

    func testToneCategoryCoversAllCases() {
        XCTAssertEqual(ToneCategory.allCases.count, 7)
        for cat in ToneCategory.allCases {
            XCTAssertFalse(cat.label.isEmpty)
            XCTAssertFalse(cat.symbol.isEmpty)
        }
    }
}
