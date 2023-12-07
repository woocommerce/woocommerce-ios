import XCTest
@testable import Networking


/// OrderListMapper Unit Tests
///
class OrderNotesMapperTests: XCTestCase {

    /// Verifies that all of the OrderNote Fields are parsed correctly.
    ///
    func test_Note_fields_are_properly_parsed() async {
        let notes = await mapLoadAllOrderNotesResponse()
        XCTAssertEqual(notes.count, 19)

        let firstNote = notes[0]
        let firstNoteCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-06-23T16:05:55")

        XCTAssertEqual(firstNote.noteID, 2260)
        XCTAssertEqual(firstNote.dateCreated, firstNoteCreated)
        XCTAssertEqual(firstNote.note, "This order is going to be a problem.")
        XCTAssertEqual(firstNote.isCustomerNote, false)
        XCTAssertEqual(firstNote.author, "someadmin")

        let secondNote = notes[1]
        let secondNoteCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-06-23T17:06:55")

        XCTAssertEqual(secondNote.noteID, 2261)
        XCTAssertEqual(secondNote.dateCreated, secondNoteCreated)
        XCTAssertEqual(secondNote.note, "I love your products!")
        XCTAssertEqual(secondNote.isCustomerNote, true)
        XCTAssertEqual(secondNote.author, "someuser")
    }

    /// Verifies that all of the OrderNote Fields are parsed correctly.
    ///
    func test_Note_fields_are_properly_parsed_when_response_has_no_data_envelope() async {
        let notes = await mapLoadAllOrderNotesResponseWithoutDataEnvelope()
        XCTAssertEqual(notes.count, 2)

        let firstNote = notes[0]
        let firstNoteCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-06-23T16:05:55")

        XCTAssertEqual(firstNote.noteID, 2260)
        XCTAssertEqual(firstNote.dateCreated, firstNoteCreated)
        XCTAssertEqual(firstNote.note, "This order is going to be a problem.")
        XCTAssertEqual(firstNote.isCustomerNote, false)
        XCTAssertEqual(firstNote.author, "someadmin")

        let secondNote = notes[1]
        let secondNoteCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-06-23T17:06:55")

        XCTAssertEqual(secondNote.noteID, 2261)
        XCTAssertEqual(secondNote.dateCreated, secondNoteCreated)
        XCTAssertEqual(secondNote.note, "I love your products!")
        XCTAssertEqual(secondNote.isCustomerNote, true)
        XCTAssertEqual(secondNote.author, "someuser")
    }

    /// Verifies that an Note in a broken state does [gets default values] | [gets skipped while parsing]
    ///
    func test_Note_has_default_dateCreated_when_null_date_received() async {
        let notes = await mapLoadBrokenOrderNotesResponse()
        XCTAssert(notes.count == 1)

        let brokenNote = notes[0]
        let format = DateFormatter()
        format.dateStyle = .short

        let orderCreatedString = format.string(from: brokenNote.dateCreated)
        let todayCreatedString = format.string(from: Date())
        XCTAssertEqual(orderCreatedString, todayCreatedString)
    }
}


/// Private Methods.
///
private extension OrderNotesMapperTests {

    /// Returns the [OrderNote] output upon receiving `filename` (Data Encoded)
    ///
    func mapNotes(from filename: String) async -> [OrderNote] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! await OrderNotesMapper().map(response: response)
    }

    /// Returns the [OrderNote] output upon receiving `order-notes`
    ///
    func mapLoadAllOrderNotesResponse() async -> [OrderNote] {
        await mapNotes(from: "order-notes")
    }

    /// Returns the [OrderNote] output upon receiving `order-notes-without-data`
    ///
    func mapLoadAllOrderNotesResponseWithoutDataEnvelope() async -> [OrderNote] {
        await mapNotes(from: "order-notes-without-data")
    }

    /// Returns the [OrderNote] output upon receiving `broken-order`
    ///
    func mapLoadBrokenOrderNotesResponse() async -> [OrderNote] {
        await mapNotes(from: "broken-notes")
    }
}
