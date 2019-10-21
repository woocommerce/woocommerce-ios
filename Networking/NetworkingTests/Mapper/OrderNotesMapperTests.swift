import XCTest

@testable import Networking

/// OrderListMapper Unit Tests
///
class OrderNotesMapperTests: XCTestCase {

    /// Verifies that all of the OrderNote Fields are parsed correctly.
    ///
    func testNoteFieldsAreProperlyParsed() {
        let notes = mapLoadAllOrderNotesResponse()
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
extension OrderNotesMapperTests {

    /// Returns the OrderNotesMapper output upon receiving `filename` (Data Encoded)
    ///
    fileprivate func mapNotes(from filename: String) -> [OrderNote] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! OrderNotesMapper().map(response: response)
    }

    /// Returns the OrderNotesMapper output upon receiving `orders-load-all`
    ///
    fileprivate func mapLoadAllOrderNotesResponse() -> [OrderNote] {
        return mapNotes(from: "order-notes")
    }

    /// Returns the OrderNotesMapper output upon receiving `broken-order`
    ///
    fileprivate func mapLoadBrokenOrderNotesResponse() -> [OrderNote] {
        return mapNotes(from: "broken-notes")
    }
}
