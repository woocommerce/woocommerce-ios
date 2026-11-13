import Foundation

/// How the Mobile Status Report travels on a Zendesk ticket.
///
/// It is sent twice on purpose. The custom field is what Happiness Engineers see beside the ticket without
/// opening anything, and the attachment survives the field's length limit — a report from a merchant with many
/// stores and every feature flag listed will outgrow it.
///
enum MobileStatusReportZendesk {

    /// The `Mobile status report` custom field, shared with the Android app so both platforms land in one place.
    static let customFieldID: Int64 = 51884914117268

    static let filename = "mobile_status_report.txt"

    private static let contentType = "text/plain"

    /// Adds the report to what a ticket already carries. The one place that encodes "the report travels twice",
    /// shared by the support form and the direct ticket creation path so the two cannot drift apart.
    static func embed(_ report: String,
                      intoCustomFields customFields: [Int64: String],
                      attachments: [ZendeskAttachment]) -> (customFields: [Int64: String], attachments: [ZendeskAttachment]) {
        var customFields = customFields
        customFields[customFieldID] = report
        return (customFields, attachments + [attachment(for: report)].compactMap { $0 })
    }

    /// `nil` when the report is empty or cannot be encoded, so a failure here drops the attachment rather than
    /// the ticket.
    private static func attachment(for report: String) -> ZendeskAttachment? {
        guard report.isNotEmpty, let data = report.data(using: .utf8) else {
            return nil
        }

        return ZendeskAttachment(data: data, filename: filename, contentType: contentType)
    }
}
