import XCTest
@testable import Networking

final class InboxNoteMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 12983476

    /// Verifies that the whole list is parsed.
    ///
    func test_InboxNoteMapper_parses_the_InboxNote_in_response() throws {
        let inboxNote = try mapLoadInboxNoteResponse()
        XCTAssertNotNil(inboxNote)
    }

    /// Verifies that the `siteID` is added in the mapper, because it's not provided by the API endpoint.
    ///
    func test_InboxNoteMapper_includes_siteID_in_parsed_result() throws {
        let inboxNote = try mapLoadInboxNoteResponse()
        XCTAssertEqual(inboxNote?.siteID, dummySiteID)
    }

    /// Verifies that the fields are all parsed correctly.
    ///
    func test_InboxNoteMapper_parses_all_fields_in_result() throws {
        // Given
        let inboxNote = try mapLoadInboxNoteResponse()

        // When
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        let url = "https://woocommerce.com/products/woocommerce-bookings/"
        let content = "Your subscription expired on October 22nd. Get a new subscription to continue receiving updates and access to support."
        let expectedInboxNote = InboxNote(siteID: dummySiteID,
                                          id: 296,
                                          name: "wc-admin-wc-helper-subscription",
                                          type: "warning",
                                          status: "unactioned",
                                          actions: [InboxAction(id: 13329,
                                                                name: "renew-subscription",
                                                                label: "Renew Subscription",
                                                                status: "actioned",
                                                                url: url)],
                                          title: "WooCommerce Bookings subscription expired",
                                          content: content,
                                          isRemoved: true,
                                          isRead: false,
                                          dateCreated: dateFormatter.date(from: "2022-01-31T14:25:32")!)

        // Then
        XCTAssertEqual(inboxNote, expectedInboxNote)
    }

    /// Verifies that `isRead` field is set to `false` when the corresponding API field (`is_read`) is not available.
    ///
    func test_InboxNoteMapper_sets_isRead_to_false_when_API_field_is_unavailable() throws {
        // When
        let inboxNote = try XCTUnwrap(mapLoadInboxNoteWithoutIsReadResponse())

        // Then
        XCTAssertFalse(inboxNote.isRead)
    }
}


// MARK: - Test Helpers
///
private extension InboxNoteMapperTests {

    /// Returns the InboxNoteMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapInboxNote(from filename: String) throws -> InboxNote? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try InboxNoteMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the InboxNoteMapper output from `inbox-note.json`
    ///
    func mapLoadInboxNoteResponse() throws -> InboxNote? {
        return try mapInboxNote(from: "inbox-note")
    }

    /// Returns the InboxNoteMapper output from `inbox-note-without-isRead.json`
    ///
    func mapLoadInboxNoteWithoutIsReadResponse() throws -> InboxNote? {
        try mapInboxNote(from: "inbox-note-without-isRead")
    }
}
