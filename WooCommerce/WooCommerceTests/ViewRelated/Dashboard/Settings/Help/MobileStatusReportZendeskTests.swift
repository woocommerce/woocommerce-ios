import Testing
import Foundation
@testable import WooCommerce

struct MobileStatusReportZendeskTests {

    @Test
    func embed_when_report_is_not_empty_then_it_is_written_to_the_custom_field_and_attached_as_a_file() {
        // Given
        let report = "# App\nVersion: 1.0"

        // When
        let (customFields, attachments) = MobileStatusReportZendesk.embed(report, intoCustomFields: [:], attachments: [])

        // Then
        #expect(customFields[MobileStatusReportZendesk.customFieldID] == report)
        #expect(attachments.count == 1)
        #expect(attachments.first?.filename == MobileStatusReportZendesk.filename)
        #expect(attachments.first?.data == report.data(using: .utf8))
    }

    @Test
    func embed_when_report_is_empty_then_the_attachment_is_dropped_but_the_custom_field_is_still_set() {
        // Given
        let report = ""

        // When
        let (customFields, attachments) = MobileStatusReportZendesk.embed(report, intoCustomFields: [:], attachments: [])

        // Then
        #expect(customFields[MobileStatusReportZendesk.customFieldID]?.isEmpty == true)
        #expect(attachments.isEmpty)
    }

    @Test
    func embed_preserves_existing_custom_fields_and_attachments() {
        // Given
        let existingCustomFields: [Int64: String] = [123: "existing value"]
        let existingAttachment = ZendeskAttachment(data: Data("existing".utf8), filename: "existing.txt", contentType: "text/plain")

        // When
        let (customFields, attachments) = MobileStatusReportZendesk.embed("report",
                                                                           intoCustomFields: existingCustomFields,
                                                                           attachments: [existingAttachment])

        // Then
        #expect(customFields[123] == "existing value")
        #expect(customFields[MobileStatusReportZendesk.customFieldID] == "report")
        #expect(attachments.count == 2)
        #expect(attachments.first?.filename == "existing.txt")
    }
}
