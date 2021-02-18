import XCTest
@testable import Networking
@testable import WooCommerce
@testable import Yosemite

final class AddAttributeOptionsViewModelTests: XCTestCase {

    private let sampleAttributeName = "attr"
    private let sampleOptionName = "new-option"

    func test_new_attribute_should_have_textfield_section() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName))

        // Then
        let textFieldSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(textFieldSection, [AddAttributeOptionsViewController.Row.optionTextField])
        XCTAssertEqual(viewModel.sections.count, 1)
    }

    func test_when_adding_new_option_to_new_attribute_a_new_section_should_be_added() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName))
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
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName))
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
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName))
        XCTAssertFalse(viewModel.isNextButtonEnabled)

        // When
        viewModel.addNewOption(name: sampleOptionName)

        // Then
        XCTAssertTrue(viewModel.isNextButtonEnabled)
    }

    func test_empty_names_are_not_added_as_options() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName))

        // When
        viewModel.addNewOption(name: "")

        // Then
        let textFieldSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(textFieldSection, [AddAttributeOptionsViewController.Row.optionTextField])
        XCTAssertEqual(viewModel.sections.count, 1)
    }

    func test_reorder_option_reorders_the_option_within_sections() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName))
        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")
        viewModel.addNewOption(name: "Option 3")

        // When
        viewModel.reorderSelectedOptions(fromIndex: 0, toIndex: 2)

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
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName))
        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")
        viewModel.addNewOption(name: "Option 3")

        // When
        viewModel.reorderSelectedOptions(fromIndex: 1, toIndex: 1)

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
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName))
        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")
        viewModel.addNewOption(name: "Option 3")

        // When
        viewModel.removeSelectedOption(atIndex: 1)

        // Then
        let optionsOffered = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(optionsOffered, [
            .selectedOptions(name: "Option 1"),
            .selectedOptions(name: "Option 3")
        ])
    }

    func test_remove_option_with_overflown_index_does_not_alter_section() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName))
        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")
        viewModel.addNewOption(name: "Option 3")

        // When
        viewModel.removeSelectedOption(atIndex: 3)

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
                self.insertSampleAttributeWithTerms(on: storage)
                onCompletion(.success(()))
            default:
                break
            }
        }

        // When
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(),
                                                     attribute: .existing(attribute: sampleAttribute()),
                                                     stores: stores,
                                                     viewStorage: storage)

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
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: sampleAttribute()), stores: stores)
        XCTAssertTrue(viewModel.showGhostTableView)

        // Then
        waitUntil {
            !viewModel.showGhostTableView
        }
    }

    func test_select_addedOption_moves_it_to_offeredSection_and_removes_it_from_addedSection() throws {
        // Given
        let storage = MockStorageManager()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: ProductAttributeTermAction.self) { action in
            switch action {
            case let .synchronizeProductAttributeTerms(_, _, onCompletion):
                self.insertSampleAttributeWithTerms(on: storage)
                onCompletion(.success(()))
            default:
                break
            }
        }

        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(),
                                                     attribute: .existing(attribute: sampleAttribute()),
                                                     stores: stores,
                                                     viewStorage: storage)

        // When
        viewModel.selectExistingOption(atIndex: 1)
        viewModel.selectExistingOption(atIndex: 1)
        waitUntil {
            viewModel.sections.count == 3
        }

        // Then
        let optionsOffered = try XCTUnwrap(viewModel.sections[1].rows)
        let optionsAdded = try XCTUnwrap(viewModel.sections[2].rows)

        XCTAssertEqual(optionsOffered, [
            .selectedOptions(name: "Option 2"),
            .selectedOptions(name: "Option 3"),
        ])
        XCTAssertEqual(optionsAdded, [
            .existingOptions(name: "Option 1"),
        ])
    }

    func test_selecting_all_added_options_removes_its_section() throws {
        // Given
        let storage = MockStorageManager()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: ProductAttributeTermAction.self) { action in
            switch action {
            case let .synchronizeProductAttributeTerms(_, _, onCompletion):
                self.insertSampleAttributeWithTerms(on: storage)
                onCompletion(.success(()))
            default:
                break
            }
        }

        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(),
                                                     attribute: .existing(attribute: sampleAttribute()),
                                                     stores: stores,
                                                     viewStorage: storage)

        let optionsAdded = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(optionsAdded, [
            .existingOptions(name: "Option 1"),
            .existingOptions(name: "Option 2"),
            .existingOptions(name: "Option 3"),
        ])

        // When
        viewModel.selectExistingOption(atIndex: 0)
        viewModel.selectExistingOption(atIndex: 0)
        viewModel.selectExistingOption(atIndex: 0)

        // Then
        let optionsOffered = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(optionsOffered, [
            .selectedOptions(name: "Option 1"),
            .selectedOptions(name: "Option 2"),
            .selectedOptions(name: "Option 3"),
        ])
    }

    func test_update_product_should_toggle_showUpdateIndicator_property() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(product, onCompletion):
                DispatchQueue.main.async {
                    onCompletion(.success(product))
                }
            default:
                break
            }
        }

        // When
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: sampleAttribute()), stores: stores)
        viewModel.updateProductAttributes(onCompletion: { _ in })

        // Then
        XCTAssertTrue(viewModel.showUpdateIndicator)
        waitUntil {
            !viewModel.showUpdateIndicator
        }
    }

    func test_updating_existing_attribute_correctly_updates_product_attributes() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(product, onCompletion):
                    onCompletion(.success(product))
            default:
                break
            }
        }

        let initialAttribute = sampleAttribute()
        let initialProduct = sampleProduct().copy(attributes: [initialAttribute])
        let viewModel = AddAttributeOptionsViewModel(product: initialProduct, attribute: .existing(attribute: initialAttribute), stores: stores)

        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")

        // When
        let updatedProduct: Product = waitFor { promise in
            viewModel.updateProductAttributes { result in
                switch result {
                case .success(let product):
                    promise(product)
                case .failure:
                    break
                }
            }
        }

        // Then
        let expectedAttribute = sampleAttribute(options: ["Option 1", "Option 2"])
        XCTAssertEqual(updatedProduct.attributes, [expectedAttribute])
    }

    func test_saving_new_attribute_does_not_override_existing_local_attribute() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProduct(product, onCompletion):
                    onCompletion(.success(product))
            default:
                break
            }
        }

        let initialAttribute = sampleAttribute(attributeID: 0, name: "attr-1")
        let initialProduct = sampleProduct().copy(attributes: [initialAttribute])
        let viewModel = AddAttributeOptionsViewModel(product: initialProduct, attribute: .new(name: "attr-2"), stores: stores)

        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")

        // When
        let updatedProduct: Product = waitFor { promise in
            viewModel.updateProductAttributes { result in
                switch result {
                case .success(let product):
                    promise(product)
                case .failure:
                    break
                }
            }
        }

        // Then
        let expectedAttribute = sampleAttribute(attributeID: 0, name: "attr-2", options: ["Option 1", "Option 2"])
        XCTAssertEqual(updatedProduct.attributes, [initialAttribute, expectedAttribute])
    }
}

// MARK: Helpers
private extension AddAttributeOptionsViewModelTests {

    func sampleProduct() -> Product {
        Product().copy(siteID: .some(123), productID: .some(12345))
    }

    func sampleAttribute(attributeID: Int64 = 1234, name: String? = nil, options: [String] = []) -> ProductAttribute {
        ProductAttribute(siteID: 123,
                         attributeID: attributeID,
                         name: name ?? sampleAttributeName,
                         position: 0,
                         visible: true,
                         variation: true,
                         options: options)
    }

    func sampleAttributeTerm(id: Int64, name: String) -> ProductAttributeTerm {
        ProductAttributeTerm(siteID: 123, termID: id, name: name, slug: name, count: 0)
    }

    func insertSampleAttributeWithTerms(on storage: MockStorageManager) {
        storage.insertSampleProductAttribute(readOnlyProductAttribute: self.sampleAttribute())
        storage.insertSampleProductAttributeTerm(readOnlyTerm: self.sampleAttributeTerm(id: 1, name: "Option 1"), onAttributeWithID: 1234)
        storage.insertSampleProductAttributeTerm(readOnlyTerm: self.sampleAttributeTerm(id: 2, name: "Option 2"), onAttributeWithID: 1234)
        storage.insertSampleProductAttributeTerm(readOnlyTerm: self.sampleAttributeTerm(id: 3, name: "Option 3"), onAttributeWithID: 1234)
    }
}
