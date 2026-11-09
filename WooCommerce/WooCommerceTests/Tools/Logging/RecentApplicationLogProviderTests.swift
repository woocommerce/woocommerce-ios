import CocoaLumberjackSwift
import Foundation
import Testing
@testable import WooCommerce

struct RecentApplicationLogProviderTests {
    @Test func test_entries_when_messages_have_different_levels_then_keeps_only_warnings_and_errors() {
        // Given
        let sut = RecentApplicationLogProvider()
        let now = Date()

        // When
        sut.loggerQueue.sync {
            sut.log(message: makeMessage("error", flag: .error, date: now))
            sut.log(message: makeMessage("warning", flag: .warning, date: now))
            sut.log(message: makeMessage("info", flag: .info, date: now))
        }

        // Then
        #expect(sut.entries(since: now.addingTimeInterval(-1), limit: 20).map(\.message) == ["error", "warning"])
    }

    @Test func test_entries_when_filtering_by_date_and_limit_then_returns_the_newest_matching_entries() {
        // Given
        let sut = RecentApplicationLogProvider()
        let now = Date()
        sut.loggerQueue.sync {
            sut.log(message: makeMessage("old", flag: .error, date: now.addingTimeInterval(-1_801)))
            sut.log(message: makeMessage("first", flag: .warning, date: now.addingTimeInterval(-2)))
            sut.log(message: makeMessage("second", flag: .error, date: now.addingTimeInterval(-1)))
        }

        // When
        let entries = sut.entries(since: now.addingTimeInterval(-1_800), limit: 1)

        // Then
        #expect(entries.map(\.message) == ["second"])
    }

    private func makeMessage(_ message: String, flag: DDLogFlag, date: Date) -> DDLogMessage {
        DDLogMessage("\(message)", level: .all, flag: flag, context: 0, file: #file, function: #function, line: #line, timestamp: date)
    }
}
