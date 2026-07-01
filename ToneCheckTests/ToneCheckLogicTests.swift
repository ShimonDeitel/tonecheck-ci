import XCTest
import SwiftData
@testable import ToneCheck

@MainActor
final class ToneCheckLogicTests: XCTestCase {

    private func makeModel() -> AppModel {
        // Use a fresh in-memory model for each test
        let model = AppModel()
        return model
    }

    func testDailyCheckCountDefaultsToZero() {
        let m = makeModel()
        UserDefaults.standard.removeObject(forKey: "tonecheck.free.count")
        UserDefaults.standard.removeObject(forKey: "tonecheck.free.day")
        XCTAssertEqual(m.dailyCheckCount, 0)
    }

    func testFreeTierAllowsFiveChecks() {
        let m = makeModel()
        UserDefaults.standard.removeObject(forKey: "tonecheck.free.count")
        UserDefaults.standard.removeObject(forKey: "tonecheck.free.day")
        XCTAssertTrue(m.canCheck(isPro: false))
        XCTAssertEqual(m.remainingFreeChecks, AppModel.freeDailyLimit)
    }

    func testToneResultIsEquatable() {
        let r1 = ToneResult(primaryTone: "Friendly", subTones: ["warm"], verdict: "Good.", rewriteSuggestion: "Fine.", grade: "A")
        let r2 = ToneResult(primaryTone: "Friendly", subTones: ["warm"], verdict: "Good.", rewriteSuggestion: "Fine.", grade: "A")
        XCTAssertEqual(r1, r2)
    }

    func testHistoryEntrySavesCorrectly() {
        let result = ToneResult(primaryTone: "Aggressive", subTones: ["harsh", "direct"], verdict: "Might offend.", rewriteSuggestion: "Soften it.", grade: "D")
        let entry = HistoryEntry(input: "You need to do this NOW.", result: result)
        XCTAssertEqual(entry.primaryTone, "Aggressive")
        XCTAssertEqual(entry.grade, "D")
        XCTAssertEqual(entry.subTones, ["harsh", "direct"])
        XCTAssertEqual(entry.toneResult.verdict, "Might offend.")
    }

    func testGradeColorMapping() {
        XCTAssertEqual(GradeHelper.color(for: "A"), "gradeA")
        XCTAssertEqual(GradeHelper.color(for: "B"), "gradeB")
        XCTAssertEqual(GradeHelper.color(for: "C"), "gradeC")
        XCTAssertEqual(GradeHelper.color(for: "D"), "gradeD")
        XCTAssertEqual(GradeHelper.color(for: "F"), "gradeF")
        XCTAssertEqual(GradeHelper.color(for: "X"), "gradeF") // unknown maps to F
    }
}
