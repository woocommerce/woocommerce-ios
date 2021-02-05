import XCTest
@testable import Networking
@testable import WooCommerce
@testable import Yosemite

final class AddAttributeOptionsViewModelTests: XCTestCase {

    private let sampleAttributeName = "attr"
    private let sampleOptionName = "new-option"

    func test_new_attribute_should_have_textfield_section() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(source: .new(name: sampleAttributeName))

        // Then
        let textFieldSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(textFieldSection, [AddAttributeOptionsViewController.Row.optionTextField])
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
        XCTAssertEqual(offeredSection, [AddAttributeOptionsViewController.Row.selectedOptions(name: sampleOptionName)])
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
        XCTAssertEqual(offeredSection, [AddAttributeOptionsViewController.Row.selectedOptions(name: sampleOptionName),
                                        AddAttributeOptionsViewController.Row.selectedOptions(name: newOptionName)])
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
            .selectedOptions(name: "Option 2"),
            .selectedOptions(name: "Option 3"),
            .selectedOptions(name: "Option 1")
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
            .selectedOptions(name: "Option 1"),
            .selectedOptions(name: "Option 2"),
            .selectedOptions(name: "Option 3")
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
            .selectedOptions(name: "Option 1"),
            .selectedOptions(name: "Option 3")
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
            .selectedOptions(name: "Option 1"),
            .selectedOptions(name: "Option 2"),
            .selectedOptions(name: "Option 3")
        ])
    }

    func test_sync_options_of_existing_attribute_creates_optionsAdded_section() throws {
        // Given
        let storage = MockStorageManager()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: ProductAttributeTermAction.self) { action in
            switch action {
            case let .synchronizeProductAttributeTerms(_, _, onCompletion):
                storage.insertSampleProductAttribute(readOnlyProductAttribute: self.sampleAttribute())
                storage.insertSampleProductAttributeTerm(readOnlyTerm: self.sampleAttributeTerm(id: 1, name: "Option 1"), onAttributeWithID: 1234)
                storage.insertSampleProductAttributeTerm(readOnlyTerm: self.sampleAttributeTerm(id: 2, name: "Option 2"), onAttributeWithID: 1234)
                storage.insertSampleProductAttributeTerm(readOnlyTerm: self.sampleAttributeTerm(id: 3, name: "Option 3"), onAttributeWithID: 1234)
                onCompletion(.success(()))
            default:
                break
            }
        }

        // When
        let viewModel = AddAttributeOptionsViewModel(source: .existing(attribute: sampleAttribute()), stores: stores, viewStorage: storage)

        waitUntil {
            return viewModel.sections.count == 2
        }

        // Then
        let optionsAdded = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(optionsAdded, [
            .existingOptions(name: "Option 1"),
            .existingOptions(name: "Option 2"),
            .existingOptions(name: "Option 3")
        ])
    }

    func test_sync_options_of_existing_attribute_should_display_and_hide_ghost_tableView() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: ProductAttributeTermAction.self) { action in
            switch action {
            case let .synchronizeProductAttributeTerms(_, _, onCompletion):
                DispatchQueue.main.async {
                    onCompletion(.success(()))
                }
            default:
                break
            }
        }

        // When
        let viewModel = AddAttributeOptionsViewModel(source: .existing(attribute: sampleAttribute()), stores: stores)
        XCTAssertTrue(viewModel.showGhostTableView)

        // Then
        waitUntil {
            !viewModel.showGhostTableView
        }
    }
}

// MARK: Helpers
private extension AddAttributeOptionsViewModelTests {
    func sampleAttribute() -> ProductAttribute {
        ProductAttribute(siteID: 123,
                         attributeID: 1234,
                         name: sampleAttributeName,
                         position: 0,
                         visible: true,
                         variation: true,
                         options: [])
    }

    func sampleAttributeTerm(id: Int64, name: String) -> ProductAttributeTerm {
        ProductAttributeTerm(siteID: 123, termID: id, name: name, slug: name, count: 0)
    }
}
