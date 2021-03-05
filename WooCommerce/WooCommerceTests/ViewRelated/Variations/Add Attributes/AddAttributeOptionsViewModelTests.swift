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

    func test_next_button_is_enabled_after_removing_preselected_options() {
        // Given
        let attribute = sampleAttribute(name: "Size", options: ["S", "M", "L"])
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: attribute))
        XCTAssertFalse(viewModel.isNextButtonEnabled)

        // When
        viewModel.removeSelectedOption(atIndex: 2)

        // Then
        XCTAssertTrue(viewModel.isNextButtonEnabled)
    }

    func test_more_button_is_not_visible_when_editing_is_disabled() {
        // Given, When
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName), allowsEditing: false)

        // Then
        XCTAssertFalse(viewModel.showMoreButton)
    }

    func test_more_button_is_visible_when_editing_is_enabled() {
        // Given, When
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName), allowsEditing: true)

        // Then
        XCTAssertTrue(viewModel.showMoreButton)
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

    func test_failed_sync_options_of_existing_attribute_should_display_error_state() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let rawError = NSError(domain: "Options Error", code: 1, userInfo: nil)
        stores.whenReceivingAction(ofType: ProductAttributeTermAction.self) { action in
            if case .synchronizeProductAttributeTerms(_, _, let onCompletion) = action {
                DispatchQueue.main.async {
                    onCompletion(.failure(.termsSynchronization(pageNumber: 0, rawError: rawError)))
                }
            }
        }

        // When
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: sampleAttribute()), stores: stores)
        XCTAssertFalse(viewModel.showSyncError)

        // Then
        waitUntil {
            viewModel.showSyncError
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
        let initialNonVarAttribute = sampleNonVariationAttribute()
        let initialProduct = sampleProduct().copy(attributes: [initialAttribute, initialNonVarAttribute])
        let viewModel = AddAttributeOptionsViewModel(product: initialProduct, attribute: .existing(attribute: initialAttribute), stores: stores)

        viewModel.setCurrentAttributeName("New Attribute Name")
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
        let expectedAttribute = sampleAttribute(name: "New Attribute Name", options: ["Option 1", "Option 2"])
        XCTAssertEqual(updatedProduct.attributes, [initialNonVarAttribute, expectedAttribute])
    }

    func test_removing_current_attribute_correctly_updates_product_attributes() throws {
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

        let attribute1 = sampleAttribute(name: "Color", options: ["Green", "Blue"])
        let attribute2 = sampleAttribute(name: "Size", options: ["Large", "Small"])
        let attribute3 = sampleNonVariationAttribute()
        let initialProduct = sampleProduct().copy(attributes: [attribute1, attribute2, attribute3])
        let viewModel = AddAttributeOptionsViewModel(product: initialProduct, attribute: .existing(attribute: attribute2), stores: stores)


        // When
        let updatedProduct: Product = waitFor { promise in
            viewModel.removeCurrentAttribute { result in
                switch result {
                case .success(let product):
                    promise(product)
                case .failure:
                    break
                }
            }
        }

        // Then
        XCTAssertEqual(updatedProduct.attributes, [attribute1, attribute3])
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
        let initialNonVarAttribute = sampleNonVariationAttribute()
        let initialProduct = sampleProduct().copy(attributes: [initialAttribute, initialNonVarAttribute])
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
        XCTAssertEqual(updatedProduct.attributes, [initialAttribute, initialNonVarAttribute, expectedAttribute])
    }

    func test_existing_local_attribute_should_preselect_options() throws {
        // Given
        let attribute = sampleAttribute(attributeID: 0, name: "Color", options: ["Green", "Blue", "Red"])
        XCTAssertTrue(attribute.isLocal)

        // When
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: attribute))

        // Then
        let textFieldSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(textFieldSection, [
            AddAttributeOptionsViewController.Row.selectedOptions(name: "Green"),
            AddAttributeOptionsViewController.Row.selectedOptions(name: "Blue"),
            AddAttributeOptionsViewController.Row.selectedOptions(name: "Red")
        ])
    }

    func test_existing_global_attribute_should_preselect_options() throws {
        // Given
        let attribute = sampleAttribute(name: "Size", options: ["S", "M", "L"])
        XCTAssertTrue(attribute.isGlobal)

        // When
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: attribute))

        // Then
        let textFieldSection = try XCTUnwrap(viewModel.sections.last?.rows)
        XCTAssertEqual(textFieldSection, [
            AddAttributeOptionsViewController.Row.selectedOptions(name: "S"),
            AddAttributeOptionsViewController.Row.selectedOptions(name: "M"),
            AddAttributeOptionsViewController.Row.selectedOptions(name: "L")
        ])
    }

    func test_new_attribute_should_allow_reorder() throws {
        // Given
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .new(name: sampleAttributeName))

        // When
        viewModel.addNewOption(name: "Option 1")
        viewModel.addNewOption(name: "Option 2")

        // Then
        let selectedSection = try XCTUnwrap(viewModel.sections.last)
        XCTAssertTrue(selectedSection.allowsReorder)
    }

    func test_local_attribute_should_allow_reorder() throws {
        // Given, When
        let attribute = sampleAttribute(attributeID: 0, name: "Color", options: ["Green", "Blue", "Red"])
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: attribute))


        // Then
        let selectedSection = try XCTUnwrap(viewModel.sections.last)
        XCTAssertTrue(selectedSection.allowsReorder)
        XCTAssertTrue(attribute.isLocal)
    }

    func test_global_attribute_should_not_allow_reorder() throws {
        // Given, When
        let attribute = sampleAttribute(name: "Color", options: ["Green", "Blue", "Red"])
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: attribute))


        // Then
        let selectedSection = try XCTUnwrap(viewModel.sections.last)
        XCTAssertFalse(selectedSection.allowsReorder)
        XCTAssertTrue(attribute.isGlobal)
    }

    func test_local_attribute_should_allow_rename() {
        // Given, When
        let attribute = sampleAttribute(attributeID: 0, name: "Color", options: ["Green", "Blue", "Red"])
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: attribute))

        // Then
        XCTAssertTrue(attribute.isLocal)
        XCTAssertTrue(viewModel.allowsRename)
    }

    func test_global_attribute_should_not_allow_rename() {
        // Given, When
        let attribute = sampleAttribute(name: "Color", options: ["Green", "Blue", "Red"])
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: attribute))

        // Then
        XCTAssertTrue(attribute.isGlobal)
        XCTAssertFalse(viewModel.allowsRename)
    }

    func test_next_button_is_enabled_after_renaming_attribute() {
        // Given
        let attribute = sampleAttribute(name: "Color", options: ["Green", "Blue", "Red"])
        let viewModel = AddAttributeOptionsViewModel(product: sampleProduct(), attribute: .existing(attribute: attribute))
        XCTAssertFalse(viewModel.isNextButtonEnabled)

        // When
        viewModel.setCurrentAttributeName("New Color")

        // Then
        XCTAssertTrue(viewModel.isNextButtonEnabled)
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

    func sampleNonVariationAttribute(attributeID: Int64 = 9999, name: String? = nil, options: [String] = []) -> ProductAttribute {
        ProductAttribute(siteID: 123,
                         attributeID: attributeID,
                         name: name ?? sampleAttributeName,
                         position: 0,
                         visible: true,
                         variation: false,
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
