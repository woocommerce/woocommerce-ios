import Foundation
import XCTest
@testable import WooCommerce

/// Tests for `ValueOneTableViewCell`.
///
final class ValueOneTableViewCellTests: XCTestCase {

    func test_cell_is_configured_with_correct_values_from_the_view_model() throws {
        // Given
        let nib = try XCTUnwrap(Bundle.main.loadNibNamed("ValueOneTableViewCell", owner: self, options: nil))
        let cell = try XCTUnwrap(nib.first as? ValueOneTableViewCell)

        let viewModel = ValueOneTableViewCell.ViewModel(text: "Text", detailText: "DetailText")

        // When
        cell.configure(with: viewModel)

        // Then
        XCTAssertEqual(viewModel.text, cell.textLabel?.text)
        XCTAssertEqual(viewModel.detailText, cell.detailTextLabel?.text)
    }
}
