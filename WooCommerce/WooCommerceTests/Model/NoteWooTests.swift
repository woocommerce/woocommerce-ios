import XCTest
import Foundation
@testable import WooCommerce
@testable import Networking


/// Note+Woo Tests
///
class NoteWooTests: XCTestCase {

    /// Sample Notes
    ///
    private lazy var sampleNotes: [Note] = {
        return try! mapNotes(from: "notifications-load-all")
    }()


    /// Verifies that `blockForSubject` returns the first block in the `.subject` collection.
    ///
    func testBlockForSubjectReturnsTheFirstBlockInTheSubjectArray() {
        for note in sampleNotes {
            XCTAssertEqual(note.blockForSubject, note.subject.first)
        }
    }

    /// Verifies that `blockForSnippet` returns the last block in the `.subject` collection, whenever there's at least 2 subject
    /// blocks.
    ///
    func testBlockForSnippetReturnsTheLastSubjectBlockWheneverThereIsMoreThanOneEntityInSuchArray() {
        for note in sampleNotes {
            let expected = (note.subject.count > 1) ? note.subject.last : nil
            XCTAssertEqual(note.blockForSnippet, expected)
        }
    }

    /// Verifies that the Product Metadata is successfully extracted from Store Review Notifications.
    ///
    func testProductMetadataIsSuccessfullyExtractedFromStoreReviewNotification() {
        guard let reviewNote = sampleNotes.first(where: { $0.subkind == .storeReview }), let product = reviewNote.product else {
            XCTFail()
            return
        }

        XCTAssertEqual(product.name, "ARC Reactor")
        XCTAssertEqual(product.url.absoluteString, "https://ofrerataanmteat-staanre-dnlu-1.blog/product/arc-reactor/")
    }

    /// Verifies that no Product Metadata can be extracted from non Store Review Notifications.
    ///
    func testProductMetadataIsNullForNonReviewNotifications() {
        for note in sampleNotes where note.subkind != .storeReview {
            XCTAssertNil(note.product)
        }
    }

    /// Verifies that the Star Rating property can be effectively extracted from Store Review Notifications.
    ///
    func testStarRatingIsSuccessfullyExtractedFromStoreReviewNotification() {
        guard let reviewNote = sampleNotes.first(where: { $0.subkind == .storeReview }) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reviewNote.starRating, 5)
    }

    /// Verifies that no Star Rating can be extracted from non Store Review Notifications.
    ///
    func testStarRatingCalculatedPropertyReturnsNilWheneverTheReceiverIsNotAStoreReviewNote() {
        for note in sampleNotes where note.subkind != .storeReview {
            XCTAssertNil(note.starRating)
        }
    }
}


/// Private Methods.
///
private extension NoteWooTests {

    /// Returns the NoteListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapNotes(from filename: String) throws -> [Note] {
        let response = Loader.contentsOf(filename)!
        return try NoteListMapper().map(response: response)
    }
}
