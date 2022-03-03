import Foundation
import XCTest
@testable import WooCommerce

/// Tests for `ValueOneTableViewCell`.
///
final class ValueOneTableViewCellTests: XCTestCase {
    private var cell: ValueOneTableViewCell!

    override func setUpWithError() throws {
        super.setUp()
        let nib = try XCTUnwrap(Bundle.main.loadNibNamed("ValueOneTableViewCell", owner: self, options: nil))
        cell = try XCTUnwrap(nib.first as? ValueOneTableViewCell)
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func test_cell_is_configured_with_correct_values_from_the_view_model() {
        // Given
        let viewModel = ValueOneTableViewCell.ViewModel(text: "Text", detailText: "DetailText")

        // When
        cell.configure(with: viewModel)

        // Then
        XCTAssertEqual(viewModel.text, cell.textLabel?.text)
        XCTAssertEqual(viewModel.detailText, cell.detailTextLabel?.text)
    }

    func test_primary_style_of_text_label() throws {
        // When
        cell.apply(style: .primary)

        // Then
        XCTAssertEqual(cell?.textLabel?.font, UIFont.body)
        XCTAssertEqual(cell?.textLabel?.textColor, UIColor.text)
        let adjustsFontForContentSizeCategory = try XCTUnwrap(cell?.textLabel?.adjustsFontForContentSizeCategory)
        XCTAssertTrue(adjustsFontForContentSizeCategory)
    }

    func test_secondary_style_of_text_label() throws {
        // When
        cell.apply(style: .secondary)

        // Then
        XCTAssertEqual(cell?.textLabel?.font, UIFont.body)
        XCTAssertEqual(cell?.textLabel?.textColor, UIColor.text)
        let adjustsFontForContentSizeCategory = try XCTUnwrap(cell?.textLabel?.adjustsFontForContentSizeCategory)
        XCTAssertTrue(adjustsFontForContentSizeCategory)
    }

    func test_primary_style__of_detail_text_label() throws {
        // When
        cell.apply(style: .primary)

        // Then
        XCTAssertEqual(cell?.detailTextLabel?.font, UIFont.subheadline)
        XCTAssertEqual(cell?.detailTextLabel?.textColor, UIColor.secondaryLabel)
        let adjustsFontForContentSizeCategory = try XCTUnwrap(cell?.detailTextLabel?.adjustsFontForContentSizeCategory)
        XCTAssertTrue(adjustsFontForContentSizeCategory)
        XCTAssertEqual(cell?.detailTextLabel?.lineBreakMode, .byWordWrapping)
        XCTAssertEqual(cell?.detailTextLabel?.numberOfLines, 0)
    }

    func test_secondary_style__of_detail_text_label() throws {
        // When
        cell.apply(style: .secondary)

        // Then
        XCTAssertEqual(cell?.detailTextLabel?.font, UIFont.subheadline)
        XCTAssertEqual(cell?.detailTextLabel?.textColor, UIColor.textTertiary)
        let adjustsFontForContentSizeCategory = try XCTUnwrap(cell?.detailTextLabel?.adjustsFontForContentSizeCategory)
        XCTAssertTrue(adjustsFontForContentSizeCategory)
        XCTAssertEqual(cell?.detailTextLabel?.lineBreakMode, .byWordWrapping)
        XCTAssertEqual(cell?.detailTextLabel?.numberOfLines, 0)
    }
}
