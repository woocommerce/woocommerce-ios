import SwiftUI
import XCTest
@testable import WooCommerce

final class BoldableTextParserTests: XCTestCase {
    func test_content_without_matching_asterisks() throws {
        // When
        let elements = BoldableTextParser().parseBoldableElements(string: "I will **never stop learning.")

        // Then
        XCTAssertEqual(elements, [.init(content: "I will **never stop learning.", isBold: false)])
    }

    func test_content_with_single_matching_asterisks_are_not_bolded() throws {
        // When
        let elements = BoldableTextParser().parseBoldableElements(string: "I will *never stop learning*.")

        // Then
        XCTAssertEqual(elements, [.init(content: "I will *never stop learning*.", isBold: false)])
    }

    func test_content_with_one_bolded_text_in_the_middle() throws {
        // When
        let elements = BoldableTextParser().parseBoldableElements(string: "I will **never stop learning**.")

        // Then
        XCTAssertEqual(elements, [
            .init(content: "I will ", isBold: false),
            .init(content: "never stop learning", isBold: true),
            .init(content: ".", isBold: false)
        ])
    }

    func test_content_with_bolded_text_in_the_beginning_and_in_the_middle() throws {
        // When
        let elements = BoldableTextParser().parseBoldableElements(string: "**Never** will I **stop learning**.")

        // Then
        XCTAssertEqual(elements, [
            .init(content: "Never", isBold: true),
            .init(content: " will I ", isBold: false),
            .init(content: "stop learning", isBold: true),
            .init(content: ".", isBold: false)
        ])
    }

    func test_content_with_bolded_text_at_the_end() throws {
        // When
        let elements = BoldableTextParser().parseBoldableElements(string: "I will **never stop learning.**")

        // Then
        XCTAssertEqual(elements, [
            .init(content: "I will ", isBold: false),
            .init(content: "never stop learning.", isBold: true),
        ])
    }

    func test_content_with_fully_bolded_text() throws {
        // When
        let elements = BoldableTextParser().parseBoldableElements(string: "**I will never stop learning.**")

        // Then
        XCTAssertEqual(elements, [.init(content: "I will never stop learning.", isBold: true)])
    }

    func test_content_without_bolded_text() throws {
        // When
        let elements = BoldableTextParser().parseBoldableElements(string: "I will never stop learning.")

        // Then
        XCTAssertEqual(elements, [.init(content: "I will never stop learning.", isBold: false)])
    }
}
