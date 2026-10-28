import Foundation
import XCTest
@testable import WooCommerce

/// Tests for `ValueOneTableViewCell`.
///
@MainActor
final class ValueOneTableViewCellTests: XCTestCase {
    func test_cell_is_configured_with_correct_values_from_the_view_model() throws {
        // Given
        let cell = try makeCell()
        let viewModel = ValueOneTableViewCell.ViewModel(text: "Text", detailText: "DetailText")

        // When
        cell.configure(with: viewModel)

        // Then
        XCTAssertEqual(viewModel.text, cell.textLabel?.text)
        XCTAssertEqual(viewModel.detailText, cell.detailTextLabel?.text)
    }

    func test_primary_style_of_text_label() throws {
        // Given
        let cell = try makeCell()

        // When
        cell.apply(style: .primary)

        // Then
        XCTAssertEqual(cell.textLabel?.font, UIFont.body)
        XCTAssertEqual(cell.textLabel?.textColor, UIColor.text)
        let adjustsFontForContentSizeCategory = try XCTUnwrap(cell.textLabel?.adjustsFontForContentSizeCategory)
        XCTAssertTrue(adjustsFontForContentSizeCategory)
    }

    func test_secondary_style_of_text_label() throws {
        // Given
        let cell = try makeCell()

        // When
        cell.apply(style: .secondary)

        // Then
        XCTAssertEqual(cell.textLabel?.font, UIFont.body)
        XCTAssertEqual(cell.textLabel?.textColor, UIColor.text)
        let adjustsFontForContentSizeCategory = try XCTUnwrap(cell.textLabel?.adjustsFontForContentSizeCategory)
        XCTAssertTrue(adjustsFontForContentSizeCategory)
    }

    func test_primary_style__of_detail_text_label() throws {
        // Given
        let cell = try makeCell()

        // When
        cell.apply(style: .primary)

        // Then
        XCTAssertEqual(cell.detailTextLabel?.font, UIFont.subheadline)
        XCTAssertEqual(cell.detailTextLabel?.textColor, UIColor.secondaryLabel)
        let adjustsFontForContentSizeCategory = try XCTUnwrap(cell.detailTextLabel?.adjustsFontForContentSizeCategory)
        XCTAssertTrue(adjustsFontForContentSizeCategory)
        XCTAssertEqual(cell.detailTextLabel?.lineBreakMode, .byWordWrapping)
        XCTAssertEqual(cell.detailTextLabel?.numberOfLines, 0)
    }

    func test_secondary_style__of_detail_text_label() throws {
        // Given
        let cell = try makeCell()

        // When
        cell.apply(style: .secondary)

        // Then
        XCTAssertEqual(cell.detailTextLabel?.font, UIFont.subheadline)
        XCTAssertEqual(cell.detailTextLabel?.textColor, UIColor.textTertiary)
        let adjustsFontForContentSizeCategory = try XCTUnwrap(cell.detailTextLabel?.adjustsFontForContentSizeCategory)
        XCTAssertTrue(adjustsFontForContentSizeCategory)
        XCTAssertEqual(cell.detailTextLabel?.lineBreakMode, .byWordWrapping)
        XCTAssertEqual(cell.detailTextLabel?.numberOfLines, 0)
    }

    private func makeCell() throws -> ValueOneTableViewCell {
        let nib = try XCTUnwrap(Bundle.main.loadNibNamed("ValueOneTableViewCell", owner: nil, options: nil))
        return try XCTUnwrap(nib.first as? ValueOneTableViewCell)
    }
}
