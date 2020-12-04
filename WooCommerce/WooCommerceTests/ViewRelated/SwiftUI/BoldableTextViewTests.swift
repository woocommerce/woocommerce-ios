import SwiftUI
import XCTest
@testable import WooCommerce

final class BoldableTextViewTests: XCTestCase {
    func test_content_without_matching_asterisks() throws {
        // When
        let view = BoldableTextView("I will *never stop learning.")

        // Then
        let text = try XCTUnwrap(view.body as? Text)
        let expectedText = Text("") + Text(verbatim: "I will *never stop learning.")
        XCTAssertEqual(text, expectedText)
    }

    func test_content_with_one_bolded_text_in_the_middle() throws {
        // When
        let view = BoldableTextView("I will *never stop learning*.")

        // Then
        let text = try XCTUnwrap(view.body as? Text)
        let expectedText = Text("") + Text(verbatim: "I will ") + Text(verbatim: "never stop learning").fontWeight(.bold) + Text(verbatim: ".")
        XCTAssertEqual(text, expectedText)
    }

    func test_content_with_bolded_text_in_the_beginning_and_in_the_middle() throws {
        // When
        let view = BoldableTextView("*Never* will I *stop learning*.")

        // Then
        let text = try XCTUnwrap(view.body as? Text)
        let expectedText = Text("")
            + Text(verbatim: "Never").fontWeight(.bold)
            + Text(verbatim: " will I ")
            + Text(verbatim: "stop learning").fontWeight(.bold)
            + Text(verbatim: ".")
        XCTAssertEqual(text, expectedText)
    }

    func test_content_with_bolded_text_at_the_end() throws {
        // When
        let view = BoldableTextView("I will *never stop learning.*")

        // Then
        let text = try XCTUnwrap(view.body as? Text)
        let expectedText = Text("") + Text(verbatim: "I will ") + Text(verbatim: "never stop learning.").fontWeight(.bold)
        XCTAssertEqual(text, expectedText)
    }

    func test_content_with_fully_bolded_text() throws {
        // When
        let view = BoldableTextView("*I will never stop learning.*")

        // Then
        let text = try XCTUnwrap(view.body as? Text)
        let expectedText = Text("") + Text(verbatim: "I will never stop learning.").fontWeight(.bold)
        XCTAssertEqual(text, expectedText)
    }

    func test_content_without_bolded_text() throws {
        // When
        let view = BoldableTextView("I will never stop learning.")

        // Then
        let text = try XCTUnwrap(view.body as? Text)
        let expectedText = Text("") + Text(verbatim: "I will never stop learning.")
        XCTAssertEqual(text, expectedText)
    }
}
