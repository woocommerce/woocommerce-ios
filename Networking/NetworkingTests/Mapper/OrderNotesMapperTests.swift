import XCTest
@testable import Networking


/// OrderListMapper Unit Tests
///
class OrderNotesMapperTests: XCTestCase {

    /// Verifies that all of the OrderNote Fields are parsed correctly.
    ///
    func testNoteFieldsAreProperlyParsed() {
        let notes = mapLoadAllOrderNotesResponse()
        XCTAssertEqual(notes.count, 18)

        let firstNote = notes[0]
        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-06-23T17:06:55")

        XCTAssertEqual(firstNote.noteId, 2261)
        XCTAssertEqual(firstNote.dateCreated, dateCreated)
        XCTAssertEqual(firstNote.note, "I love your products!")
        XCTAssertEqual(firstNote.isCustomerNote, true)
    }

    /// Verifies that an Note in a broken state does [gets default values] | [gets skipped while parsing]
    ///
    func testNoteHasDefaultDateCreatedWhenNullDateReceived() {
        let notes = mapLoadBrokenOrderNotesResponse()
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

    /// Returns the OrderNotesMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapNotes(from filename: String) -> [OrderNote] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! OrderNotesMapper().map(response: response)
    }

    /// Returns the OrderNotesMapper output upon receiving `orders-load-all`
    ///
    func mapLoadAllOrderNotesResponse() -> [OrderNote] {
        return mapNotes(from: "order-notes")
    }

    /// Returns the OrderNotesMapper output upon receiving `broken-order`
    ///
    func mapLoadBrokenOrderNotesResponse() -> [OrderNote] {
        return mapNotes(from: "broken-notes")
    }
}
