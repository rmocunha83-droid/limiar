import XCTest
@testable import Limiar

final class LocalReadingSessionTests: XCTestCase {
    func testLocalFactoryRespectsRequestedCountAndKeepsOnlyCanonicalReading() {
        let passages = (1...3).map { index in
            ScripturePassage(
                id: "passage-\(index)",
                tradition: .catholic,
                title: "Trecho \(index)",
                reference: "Salmo \(index)",
                text: "Texto canônico \(index)",
                estimatedMinutes: 5,
                theme: .hope,
                section: .psalms,
                book: .psalms
            )
        }

        for count in 1...3 {
            let items = LocalReadingSessionFactory.items(from: passages, itemCount: count)

            XCTAssertEqual(items.count, count)
            XCTAssertEqual(items.map(\.passageID), passages.prefix(count).map { Optional($0.id) })
            XCTAssertTrue(items.allSatisfy { $0.homily.isEmpty })
            XCTAssertTrue(items.allSatisfy { $0.practicalConclusion.isEmpty })
            XCTAssertTrue(items.allSatisfy { !$0.hasExplanationContent })
        }
    }

    func testSnapshotPersistsLocalSourceAndFailureReason() throws {
        let snapshot = DailyReadingSessionSnapshot(
            dayKey: "2026-07-20",
            profileKey: "profile",
            items: [],
            reflection: emptyReflection,
            source: .local,
            failureReason: "url_error_-1009"
        )

        let decoded = try JSONDecoder().decode(
            DailyReadingSessionSnapshot.self,
            from: JSONEncoder().encode(snapshot)
        )

        XCTAssertEqual(decoded.source, .local)
        XCTAssertEqual(decoded.failureReason, "url_error_-1009")
    }

    func testLegacySnapshotDefaultsToRemoteSource() throws {
        let snapshot = DailyReadingSessionSnapshot(
            dayKey: "2026-07-20",
            profileKey: "profile",
            items: [],
            reflection: emptyReflection
        )
        let encoded = try JSONEncoder().encode(snapshot)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "source")
        object.removeValue(forKey: "failureReason")

        let decoded = try JSONDecoder().decode(
            DailyReadingSessionSnapshot.self,
            from: JSONSerialization.data(withJSONObject: object)
        )

        XCTAssertEqual(decoded.source, .remote)
        XCTAssertNil(decoded.failureReason)
    }

    func testUpgradeOnlyRunsBeforeTraversalAndCycleCompletion() {
        XCTAssertTrue(
            LocalSessionUpgradePolicy.shouldAttempt(
                source: .local,
                isReadingSessionActive: false,
                hasCompletedCurrentCycle: false
            )
        )
        XCTAssertFalse(
            LocalSessionUpgradePolicy.shouldAttempt(
                source: .remote,
                isReadingSessionActive: false,
                hasCompletedCurrentCycle: false
            )
        )
        XCTAssertFalse(
            LocalSessionUpgradePolicy.shouldAttempt(
                source: .local,
                isReadingSessionActive: true,
                hasCompletedCurrentCycle: false
            )
        )
        XCTAssertFalse(
            LocalSessionUpgradePolicy.shouldAttempt(
                source: .local,
                isReadingSessionActive: false,
                hasCompletedCurrentCycle: true
            )
        )
    }

    private var emptyReflection: AIReflection {
        AIReflection(
            summary: "",
            spiritualMeaning: "",
            practicalApplication: "",
            conclusion: "",
            meditationQuestion: ""
        )
    }
}
