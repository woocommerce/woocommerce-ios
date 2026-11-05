import Foundation
import Testing
@testable import WooCommerce

struct RecentApplicationLogsContextTests {
    private let now = Date(timeIntervalSince1970: 1_798_000_000)

    @Test func test_build_when_logs_contain_sensitive_data_then_cleans_each_first_line() throws {
        // Given
        let message = "pass\u{200B}word=hunter2 email=merchant@example.com " +
            "url=https://example.com/path?foo=bar Bearer abc123 192.168.1.2 " +
            "2001:db8::1 2001:0db8:85a3:0000:0000:8a2e:0370:7334 at 10:20:30\nsecret second line"
        let sut = makeSUT(entries: [.init(date: now, level: .warning, message: message)])

        // When
        let result = try #require(sut.build(excludingStoreResponseExcerpts: false))

        // Then
        #expect(result.entryCount == 1)
        #expect(result.text.contains("# Recent app logs"))
        #expect(result.text.contains("password=[redacted]"))
        #expect(result.text.contains("[email]"))
        #expect(result.text.contains("?[redacted]"))
        #expect(result.text.contains("Bearer [redacted]"))
        #expect(result.text.contains("[ip]"))
        #expect(!result.text.contains("hunter2"))
        #expect(!result.text.contains("merchant@example.com"))
        #expect(!result.text.contains("2001:db8::1"))
        #expect(!result.text.contains("2001:0db8:85a3:0000:0000:8a2e:0370:7334"))
        #expect(result.text.contains("at 10:20:30"))
        #expect(!result.text.contains("secret second line"))
    }

    @Test func test_build_when_excluding_store_response_excerpts_then_removes_only_the_excerpt() throws {
        // Given
        let message = "Unexpected store response: kind=unexpected_content, status=503, excerpt=Maintenance mode"
        let rawBodyMessage = "Jetpack Tunnel raw_body error: raw_body_truncated=false, raw_body_snippet=<html>Failure</html>"
        let sut = makeSUT(entries: [
            .init(date: now, level: .error, message: message),
            .init(date: now, level: .warning, message: rawBodyMessage)
        ])

        // When
        let result = try #require(sut.build(excludingStoreResponseExcerpts: true))

        // Then
        #expect(result.text.contains("Unexpected store response: kind=unexpected_content, status=503"))
        #expect(!result.text.contains("Maintenance mode"))
        #expect(!result.text.contains("excerpt="))
        #expect(result.text.contains("raw_body_snippet=<html>Failure</html>"))
    }

    @Test func test_build_when_more_than_twenty_logs_exist_then_keeps_the_newest_twenty() throws {
        // Given
        let entries = (0..<25).map { index in
            RecentApplicationLogEntry(date: now.addingTimeInterval(TimeInterval(index)), level: .warning, message: "message \(index)")
        }
        let sut = makeSUT(entries: entries)

        // When
        let result = try #require(sut.build(excludingStoreResponseExcerpts: false))

        // Then
        #expect(result.entryCount == 20)
        #expect(result.text.contains("message 5"))
        #expect(result.text.contains("message 24"))
        #expect(!result.text.contains("message 4"))
    }

    @Test func test_build_when_section_exceeds_limit_then_keeps_only_the_newest_complete_lines() throws {
        // Given
        let entries = (0..<20).map { index in
            RecentApplicationLogEntry(date: now.addingTimeInterval(TimeInterval(index)), level: .error,
                                      message: "\(index) " + String(repeating: "value ", count: 120))
        }
        let sut = makeSUT(entries: entries)

        // When
        let result = try #require(sut.build(excludingStoreResponseExcerpts: false))

        // Then
        #expect(result.entryCount == 7)
        let logLines = result.text.split(separator: "\n").filter { $0.first == "[" }
        #expect(logLines.allSatisfy { $0.count <= 500 })
        #expect(result.text.contains("] 19 "))
        #expect(!result.text.contains("] 12 "))
    }

    @Test func test_build_when_logs_are_older_than_thirty_minutes_then_returns_nil() {
        // Given
        let sut = makeSUT(entries: [.init(date: now.addingTimeInterval(-1_801), level: .error, message: "old")])

        // When / Then
        #expect(sut.build(excludingStoreResponseExcerpts: false) == nil)
    }

    private func makeSUT(entries: [RecentApplicationLogEntry]) -> RecentApplicationLogsContext {
        RecentApplicationLogsContext(provider: MockRecentApplicationLogProvider(logEntries: entries), now: { now })
    }
}
