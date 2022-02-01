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
        let url = "https://woocommerce.com/posts/pre-launch-checklist-the-essentials/?utm_source=inbox&utm_medium=product"
        let content = "To make sure you never get that sinking \"what did I forget\" feeling, we've put together the essential pre-launch checklist."
        let expectedInboxNote = InboxNote(siteID: dummySiteID,
                                          id: 291,
                                          name: "wc-admin-launch-checklist",
                                          type: "info",
                                          status: "unactioned",
                                          actions: [InboxAction(id: 13225,
                                                                name: "learn-more",
                                                                label: "Learn more",
                                                                status: "actioned",
                                                                url: url)],
                                          title: "Ready to launch your store?",
                                          content: content,
                                          isDeleted: false,
                                          isRead: false,
                                          dateCreated: dateFormatter.date(from: "2022-01-26T14:32:08")!)

        // Then
        XCTAssertEqual(inboxNote, expectedInboxNote)
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
}
