import XCTest
@testable import WooCommerce

final class AddAttributeOptionsViewModelTests: XCTestCase {

    private let sampleAttributeName = "attr"
    private let sampleOptionName = "new-option"

    func test_new_attribute_should_have_textfield_section() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(source: .new(name: sampleAttributeName))

        // Then
        let textFieldSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(textFieldSection, [AddAttributeOptionsViewController.Row.termTextField])
        XCTAssertEqual(viewModel.sections.count, 1)
    }

    func test_when_adding_new_option_to_new_attribute_a_new_section_should_be_added() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(source: .new(name: sampleAttributeName))
        XCTAssertEqual(viewModel.sections.count, 1) // Option Name Section

        // When
        viewModel.addNewOption(name: sampleOptionName)

        // Then
        let offeredSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(offeredSection, [AddAttributeOptionsViewController.Row.selectedTerms(name: sampleOptionName)])
        XCTAssertEqual(viewModel.sections.count, 2)
    }

    func test_when_adding_multiple_options_one_section_with_multiple_rows_is_added() throws {
        // Given
        let newOptionName = "new-option-2"
        let viewModel = AddAttributeOptionsViewModel(source: .new(name: sampleAttributeName))
        XCTAssertEqual(viewModel.sections.count, 1) // Option Name Section

        // When
        viewModel.addNewOption(name: sampleOptionName)
        viewModel.addNewOption(name: newOptionName)

        // Then
        let offeredSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(offeredSection, [AddAttributeOptionsViewController.Row.selectedTerms(name: sampleOptionName),
                                        AddAttributeOptionsViewController.Row.selectedTerms(name: newOptionName)])
        XCTAssertEqual(viewModel.sections.count, 2)
    }

    func test_next_button_gets_enabled_after_adding_one_option() {
        // Given
        let viewModel = AddAttributeOptionsViewModel(source: .new(name: sampleAttributeName))
        XCTAssertFalse(viewModel.isNextButtonEnabled)

        // When
        viewModel.addNewOption(name: sampleOptionName)

        // Then
        XCTAssertTrue(viewModel.isNextButtonEnabled)
    }

    func test_reorder_option_reorders_the_option_within_sections() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(source: .new(name: sampleAttributeName))
        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")
        viewModel.addNewOption(name: "Option 3")

        // When
        viewModel.reorderOptionOffered(fromIndex: 0, toIndex: 2)

        // Then
        let optionsOffered = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(optionsOffered, [
            .selectedTerms(name: "Option 2"),
            .selectedTerms(name: "Option 3"),
            .selectedTerms(name: "Option 1")
        ])

    }

    func test_reorder_option_with_same_indexes_do_not_reorders_section() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(source: .new(name: sampleAttributeName))
        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")
        viewModel.addNewOption(name: "Option 3")

        // When
        viewModel.reorderOptionOffered(fromIndex: 1, toIndex: 1)

        // Then
        let optionsOffered = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(optionsOffered, [
            .selectedTerms(name: "Option 1"),
            .selectedTerms(name: "Option 2"),
            .selectedTerms(name: "Option 3")
        ])
    }

    func test_remove_option_with_correct_index_removes_it_from_section() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(source: .new(name: sampleAttributeName))
        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")
        viewModel.addNewOption(name: "Option 3")

        // When
        viewModel.removeOptionOffered(atIndex: 1)

        // Then
        let optionsOffered = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(optionsOffered, [
            .selectedTerms(name: "Option 1"),
            .selectedTerms(name: "Option 3")
        ])
    }

    func test_remove_option_with_overflown_index_does_not_alter_section() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(source: .new(name: sampleAttributeName))
        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")
        viewModel.addNewOption(name: "Option 3")

        // When
        viewModel.removeOptionOffered(atIndex: 3)

        // Then
        let optionsOffered = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(optionsOffered, [
            .selectedTerms(name: "Option 1"),
            .selectedTerms(name: "Option 2"),
            .selectedTerms(name: "Option 3")
        ])
    }
}
