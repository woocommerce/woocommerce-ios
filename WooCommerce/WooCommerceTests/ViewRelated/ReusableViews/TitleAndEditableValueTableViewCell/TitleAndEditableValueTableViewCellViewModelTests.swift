import XCTest

@testable import WooCommerce

/// Test cases for `TitleAndEditableValueTableViewCellViewModel`.
///
final class TitleAndEditableValueTableViewCellViewModelTests: XCTestCase {

    func test_value_Observable_emits_new_values_when_update_is_called() {
        // Given
        let viewModel = TitleAndEditableValueTableViewCellViewModel(title: nil)

        var emittedValues = [String?]()
        _ = viewModel.value.subscribe {
            emittedValues.append($0)
        }

        // When
        viewModel.update(value: "et")
        viewModel.update(value: nil)
        viewModel.update(value: "aut")
        viewModel.update(value: "laudantium")
        viewModel.update(value: nil)

        // Then
        XCTAssertEqual(emittedValues, [nil, "et", nil, "aut", "laudantium", nil])
    }

    func test_currentValue_returns_the_last_emitted_value() {
        // Given
        let viewModel = TitleAndEditableValueTableViewCellViewModel(title: nil)

        XCTAssertNil(viewModel.currentValue)

        // When
        viewModel.update(value: "aut")
        viewModel.update(value: "laudantium")

        // Then
        XCTAssertEqual(viewModel.currentValue, "laudantium")
    }
}
