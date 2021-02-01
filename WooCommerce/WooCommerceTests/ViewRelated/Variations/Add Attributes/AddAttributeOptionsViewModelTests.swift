import XCTest
@testable import WooCommerce

final class AddAttributeOptionsViewModelTests: XCTestCase {

    func test_when_adding_new_option_to_new_attribute_a_new_section_should_be_added() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(newAttribute: "attr")
        XCTAssertEqual(viewModel.sections.count, 1) // Option Name Section

        // When
        viewModel.addNewOption(name: "new-option")

        // Then
        XCTAssertEqual(viewModel.sections.count, 2)
        let offeredSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(offeredSection, [AddAttributeOptionsViewController.Row.selectedTerms])
    }
}
