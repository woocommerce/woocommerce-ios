import XCTest
import Foundation
@testable import WooCommerce
@testable import Networking


/// OrderNote+Woo Tests
///
class OrderNoteWooTests: XCTestCase {

    /// Sample OrderNotes
    ///
    private lazy var sampleOrderNotes: [OrderNote] = {
        return try! mapOrderNotes(from: "order-notes")
    }()

    /// Verifies the `isSystemNote` calculated property returns `true` when the author is system.
    ///
    func testIsSystemNoteCalculatedPropertyReturnsTrueForSystemAuthors() {
        for orderNote in sampleOrderNotes where orderNote.author == "system" {
            XCTAssertTrue(orderNote.isSystemNote)
        }
    }

    /// Verifies the `isSystemNote` calculated property returns `false` when the author is NOT system.
    ///
    func testIsSystemNoteCalculatedPropertyReturnsFalseForNonSystemAuthors() {
        for orderNote in sampleOrderNotes where orderNote.author != "system" {
            XCTAssertFalse(orderNote.isSystemNote)
        }
    }
}


/// Private Methods.
///
private extension OrderNoteWooTests {

    /// Returns the OrderNotesMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapOrderNotes(from filename: String) throws -> [OrderNote] {
        let response = Loader.contentsOf(filename)!
        return try OrderNotesMapper().map(response: response)
    }
}
