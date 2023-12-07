import XCTest
import Foundation
@testable import WooCommerce
@testable import Networking


/// OrderNote+Woo Tests
///
class OrderNoteWooTests: XCTestCase {
    /// Verifies the `isSystemNote` calculated property returns `true` when the author is system.
    ///
    func test_is_system_note_calculated_property_returns_true_for_system_authors() async throws {
        let sampleOrderNotes = try await mapOrderNotes(from: "order-notes")
        for orderNote in sampleOrderNotes where orderNote.author == "system" {
            XCTAssertTrue(orderNote.isSystemAuthor)
        }
    }

    /// Verifies the `isSystemNote` calculated property returns `false` when the author is NOT system.
    ///
    func test_is_system_note_calculated_property_returns_false_for_non_system_authors() async throws {
        let sampleOrderNotes = try await mapOrderNotes(from: "order-notes")
        for orderNote in sampleOrderNotes where orderNote.author != "system" {
            XCTAssertFalse(orderNote.isSystemAuthor)
        }
    }
}


/// Private Methods.
///
private extension OrderNoteWooTests {

    /// Returns the OrderNotesMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapOrderNotes(from filename: String) async throws -> [OrderNote] {
        let response = Loader.contentsOf(filename)!
        return try await OrderNotesMapper().map(response: response)
    }
}
