import XCTest
@testable import WooCommerce

final class AddAttributeOptionsViewModelTests: XCTestCase {

    func test_new_attribute_should_have_textfield_section() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(newAttribute: "attr")

        // Then
        let textFieldSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(textFieldSection, [AddAttributeOptionsViewController.Row.termTextField])
        XCTAssertEqual(viewModel.sections.count, 1)
    }

    func test_when_adding_new_option_to_new_attribute_a_new_section_should_be_added() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(newAttribute: "attr")
        XCTAssertEqual(viewModel.sections.count, 1) // Option Name Section

        // When
        viewModel.addNewOption(name: "new-option")

        // Then
        let offeredSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(offeredSection, [AddAttributeOptionsViewController.Row.selectedTerms])
        XCTAssertEqual(viewModel.sections.count, 2)
    }

    func test_when_adding_multiple_options_one_section_with_multiple_rows_is_added() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(newAttribute: "attr")
        XCTAssertEqual(viewModel.sections.count, 1) // Option Name Section

        // When
        viewModel.addNewOption(name: "new-option")
        viewModel.addNewOption(name: "new-option-2")

        // Then
        let offeredSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(offeredSection, [AddAttributeOptionsViewController.Row.selectedTerms,
                                        AddAttributeOptionsViewController.Row.selectedTerms])
        XCTAssertEqual(viewModel.sections.count, 2)
    }
}
