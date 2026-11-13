import Foundation
import Testing
@testable import WooCommerce

struct SupportRequestAttachmentProviderTests {
    @Test func attachments_when_application_logs_are_available_then_appends_full_log() throws {
        // Given
        let logs = "First log line\nSecond log line"
        let provider = DefaultSupportRequestAttachmentProvider(
            applicationLogProvider: MockApplicationLogProvider(logs: logs)
        )

        // When
        let attachments = provider.attachments(including: [])

        // Then
        let applicationLog = try #require(attachments.first)
        #expect(attachments.count == 1)
        #expect(applicationLog.filename == "application_log.txt")
        #expect(applicationLog.contentType == "text/plain")
        #expect(applicationLog.data == Data(logs.utf8))
    }

    @Test func attachments_when_diagnostic_is_supplied_then_preserves_it_and_appends_application_log() {
        // Given
        let diagnostic = ZendeskAttachment(data: Data("Diagnostic".utf8),
                                           filename: "connectivitytest_log.txt",
                                           contentType: "text/plain")
        let provider = DefaultSupportRequestAttachmentProvider(
            applicationLogProvider: MockApplicationLogProvider(logs: "Application log")
        )

        // When
        let attachments = provider.attachments(including: [diagnostic])

        // Then
        #expect(attachments.map(\.filename) == ["connectivitytest_log.txt", "application_log.txt"])
    }

    @Test func attachments_when_application_log_is_already_supplied_then_does_not_duplicate_it() throws {
        // Given
        let existingLog = ZendeskAttachment(data: Data("Existing log".utf8),
                                            filename: "application_log.txt",
                                            contentType: "text/plain")
        let provider = DefaultSupportRequestAttachmentProvider(
            applicationLogProvider: MockApplicationLogProvider(logs: "Replacement log")
        )

        // When
        let attachments = provider.attachments(including: [existingLog])

        // Then
        let applicationLog = try #require(attachments.first)
        #expect(attachments.count == 1)
        #expect(applicationLog.data == Data("Existing log".utf8))
    }

    @Test func attachments_when_application_logs_are_missing_then_preserves_supplied_attachments() {
        // Given
        let diagnostic = ZendeskAttachment(data: Data("Diagnostic".utf8),
                                           filename: "connectivitytest_log.txt",
                                           contentType: "text/plain")
        let provider = DefaultSupportRequestAttachmentProvider(
            applicationLogProvider: MockApplicationLogProvider(logs: nil)
        )

        // When
        let attachments = provider.attachments(including: [diagnostic])

        // Then
        #expect(attachments.map(\.filename) == ["connectivitytest_log.txt"])
    }

    @Test func attachments_when_application_logs_are_empty_then_preserves_supplied_attachments() {
        // Given
        let diagnostic = ZendeskAttachment(data: Data("Diagnostic".utf8),
                                           filename: "connectivitytest_log.txt",
                                           contentType: "text/plain")
        let provider = DefaultSupportRequestAttachmentProvider(
            applicationLogProvider: MockApplicationLogProvider(logs: "")
        )

        // When
        let attachments = provider.attachments(including: [diagnostic])

        // Then
        #expect(attachments.map(\.filename) == ["connectivitytest_log.txt"])
    }
}
