import XCTest
@testable import Networking

final class InboxNoteListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 12983476

    /// Verifies that the whole list is parsed.
    ///
    func test_InboxNoteListMapper_parses_all_InboxNotes_in_response() throws {
        let inboxNotes = try mapLoadInboxNoteListResponse()
        XCTAssertEqual(inboxNotes.count, 24)
    }

    /// Verifies that the `siteID` is added in the mapper, to all results, because it's not provided by the API endpoint.
    ///
    func test_InboxNoteListMapper_includes_siteID_in_parsed_results() throws {
        let inboxNotes = try mapLoadInboxNoteListResponse()
        XCTAssertTrue(inboxNotes.count > 0)

        for inboxNote in inboxNotes {
            XCTAssertEqual(inboxNote.siteID, dummySiteID)
        }
    }

    /// Verifies that the fields are all parsed correctly.
    ///
    func test_InboxNoteListMapper_parses_all_fields_in_result() throws {
        // Given
        let inboxNotes = try mapLoadInboxNoteListResponse()
        let inboxNote = inboxNotes[0]

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
private extension InboxNoteListMapperTests {

    /// Returns the InboxNoteListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapInboxNoteList(from filename: String) throws -> [InboxNote] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try InboxNoteListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the InboxNoteListMapper output from `inbox-note-list.json`
    ///
    func mapLoadInboxNoteListResponse() throws -> [InboxNote] {
        return try mapInboxNoteList(from: "inbox-note-list")
    }
}
