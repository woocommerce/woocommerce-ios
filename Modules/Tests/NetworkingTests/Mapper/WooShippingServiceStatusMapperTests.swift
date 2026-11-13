import Foundation
import Testing
@testable import Networking

@Suite("WooShippingServiceStatusMapper")
struct WooShippingServiceStatusMapperTests {

    @Test func test_map_when_response_has_multiple_notices_then_maps_each_notice_in_order() throws {
        // When
        let notices = try mapNotices(from: "wooshipping-service-status-success")

        // Then
        #expect(notices == [
            WooShippingServiceStatusNotice(id: "service-status-easypost-usps",
                                           severity: .error,
                                           message: "USPS: API Outage | Status: Investigating",
                                           isDismissible: false,
                                           actionURL: URL(string: "https://www.easypoststatus.com")),
            WooShippingServiceStatusNotice(id: "service-status-easypost-ups",
                                           severity: .warning,
                                           message: "UPS: Label creation delays | Status: Monitoring",
                                           isDismissible: true,
                                           actionURL: nil),
            WooShippingServiceStatusNotice(id: "service-status-easypost-dhl",
                                           severity: .info,
                                           message: "DHL Express: Scheduled maintenance tonight",
                                           isDismissible: true,
                                           actionURL: URL(string: "https://www.easypoststatus.com"))
        ])
    }

    @Test func test_map_when_response_has_data_envelope_then_maps_notices() throws {
        // When
        let notices = try mapNotices(from: "wooshipping-service-status-data-envelope")

        // Then
        #expect(notices.map(\.id) == ["service-status-easypost-usps"])
        #expect(notices.first?.severity == .warning)
    }

    @Test func test_map_when_response_has_no_notices_then_returns_empty_list() throws {
        // When
        let notices = try mapNotices(from: "wooshipping-service-status-empty")

        // Then
        #expect(notices.isEmpty)
    }

    @Test func test_map_when_notices_key_is_missing_then_returns_empty_list() throws {
        // When
        let notices = try WooShippingServiceStatusMapper().map(response: Data("{}".utf8))

        // Then
        #expect(notices.isEmpty)
    }

    @Test func test_map_when_entries_are_null_or_miss_id_or_message_then_drops_them() throws {
        // When
        let notices = try mapNotices(from: "wooshipping-service-status-invalid-entries")

        // Then
        #expect(notices.map(\.id) == ["uppercase-type", "unknown-type", "missing-type", "url-without-host"])
    }

    @Test func test_map_when_type_is_uppercase_or_unknown_then_matches_case_insensitively_and_defaults_to_info() throws {
        // When
        let notices = try mapNotices(from: "wooshipping-service-status-invalid-entries")

        // Then
        #expect(notice("uppercase-type", in: notices)?.severity == .warning)
        #expect(notice("unknown-type", in: notices)?.severity == .info)
        #expect(notice("missing-type", in: notices)?.severity == .info)
        #expect(notice("url-without-host", in: notices)?.severity == .error)
    }

    @Test func test_map_when_action_is_not_an_http_url_with_host_then_drops_the_action() throws {
        // When
        let notices = try mapNotices(from: "wooshipping-service-status-invalid-entries")

        // Then
        #expect(notice("uppercase-type", in: notices)?.actionURL == URL(string: "HTTPS://status.example.com"))
        #expect(notice("unknown-type", in: notices)?.actionURL == nil)
        #expect(notice("missing-type", in: notices)?.actionURL == nil)
        #expect(notice("url-without-host", in: notices)?.actionURL == nil)
    }

    @Test func test_map_when_entries_or_fields_have_unexpected_types_then_keeps_the_valid_notices() throws {
        // When
        let notices = try mapNotices(from: "wooshipping-service-status-malformed-entries")

        // Then
        #expect(notices == [
            WooShippingServiceStatusNotice(id: "wrong-field-types",
                                           severity: .info,
                                           message: "Wrong field types",
                                           isDismissible: false,
                                           actionURL: nil),
            WooShippingServiceStatusNotice(id: "duplicate",
                                           severity: .error,
                                           message: "First duplicate",
                                           isDismissible: false,
                                           actionURL: nil)
        ])
    }

    @Test func test_map_when_notices_is_not_an_array_then_returns_empty_list() throws {
        // When
        let notices = try WooShippingServiceStatusMapper().map(response: Data(#"{"notices": "none"}"#.utf8))

        // Then
        #expect(notices.isEmpty)
    }

    @Test func test_map_when_dismissible_is_missing_then_notice_is_not_dismissible() throws {
        // When
        let notices = try mapNotices(from: "wooshipping-service-status-invalid-entries")

        // Then
        #expect(notice("uppercase-type", in: notices)?.isDismissible == false)
        #expect(notice("unknown-type", in: notices)?.isDismissible == true)
    }
}

private extension WooShippingServiceStatusMapperTests {
    func mapNotices(from filename: String) throws -> [WooShippingServiceStatusNotice] {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }
        return try WooShippingServiceStatusMapper().map(response: response)
    }

    func notice(_ id: String, in notices: [WooShippingServiceStatusNotice]) -> WooShippingServiceStatusNotice? {
        notices.first { $0.id == id }
    }

    struct FileNotFoundError: Error {}
}
