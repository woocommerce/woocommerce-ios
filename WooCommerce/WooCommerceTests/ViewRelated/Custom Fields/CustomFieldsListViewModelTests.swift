import XCTest
@testable import WooCommerce

final class CustomFieldsListViewModelTests: XCTestCase {

    private var viewModel: CustomFieldsListViewModel!

    override func setUp() {
        super.setUp()
        let customFields = [
            CustomFieldViewModel(id: 1, title: "Key1", content: "Value1"),
            CustomFieldViewModel(id: 2, title: "Key2", content: "Value2")
        ]
        viewModel = CustomFieldsListViewModel(customFields: customFields)
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func test_given_initializedViewModel_then_displayedItemsMatchInitialCustomFields() {
        // Given: The viewModel is initialized with two custom fields (in setUp)

        // When: No additional action needed, we're testing the initial state

        // Then: The displayed items should match the initial custom fields
        XCTAssertEqual(viewModel.combinedList.count, 2)
        XCTAssertEqual(viewModel.combinedList[0].key, "Key1")
        XCTAssertEqual(viewModel.combinedList[0].value, "Value1")
        XCTAssertEqual(viewModel.combinedList[0].id, 1)
        XCTAssertEqual(viewModel.combinedList[1].key, "Key2")
        XCTAssertEqual(viewModel.combinedList[1].value, "Value2")
        XCTAssertEqual(viewModel.combinedList[1].id, 2)
    }

    func test_given_existingField_when_editFieldCalled_then_displayedItemsAndPendingChangesAreUpdated() {
        // Given: A custom field UI to edit an existing field
        let editedField = CustomFieldsListViewModel.CustomFieldUI(key: "EditedKey1", value: "EditedValue1", id: 1)

        // When: Editing the field
        viewModel.editField(at: 0, newField: editedField)

        // Then: The number of displayed items remains the same as before and the value is edited correctly
        XCTAssertEqual(viewModel.combinedList.count, 2)
        XCTAssertEqual(viewModel.combinedList[0].key, "EditedKey1")
        XCTAssertEqual(viewModel.combinedList[0].value, "EditedValue1")
    }

    func test_given_newField_when_addFieldCalled_then_displayedItemsAndPendingChangesAreUpdated() {
        // Given: A new custom field UI to add
        let newField = CustomFieldsListViewModel.CustomFieldUI(key: "NewKey", value: "NewValue")

        // When: Adding the new field
        viewModel.addField(newField)

        // Then: The pending changes and displayed items should be updated
        XCTAssertEqual(viewModel.combinedList.count, 3)
        XCTAssertEqual(viewModel.combinedList.last?.key, "NewKey")
        XCTAssertEqual(viewModel.combinedList.last?.value, "NewValue")
    }

    func test_given_editedAndNewFields_when_updatingDisplayedItems_then_changesAreReflected() {
        // Given: An edited field and a new field
        let editedField = CustomFieldsListViewModel.CustomFieldUI(key: "EditedKey1", value: "EditedValue1", id: 1)
        let newField = CustomFieldsListViewModel.CustomFieldUI(key: "NewKey", value: "NewValue")

        // When: Editing and adding fields
        viewModel.editField(at: 0, newField: editedField)
        viewModel.addField(newField)

        // Then: The displayed items should reflect both the edited and added fields
        XCTAssertEqual(viewModel.combinedList.count, 3)
        XCTAssertEqual(viewModel.combinedList[0].key, "EditedKey1")
        XCTAssertEqual(viewModel.combinedList[0].value, "EditedValue1")
        XCTAssertEqual(viewModel.combinedList[2].key, "NewKey")
        XCTAssertEqual(viewModel.combinedList[2].value, "NewValue")
    }

    func test_given_variousChanges_when_pendingChangesUpdated_then_hasChangesReflectsCorrectState() {
        // Given: Initial state with no changes
        XCTAssertFalse(viewModel.hasChanges)

        // When: Editing a field
        let editedField = CustomFieldsListViewModel.CustomFieldUI(key: "EditedKey1", value: "EditedValue1", id: 1)
        viewModel.editField(at: 0, newField: editedField)

        // Then: hasChanges should be true
        XCTAssertTrue(viewModel.hasChanges)

        // When: Adding a new field
        let newField = CustomFieldsListViewModel.CustomFieldUI(key: "NewKey", value: "NewValue")
        viewModel.addField(newField)

        // Then: hasChanges should be true
        XCTAssertTrue(viewModel.hasChanges)

    func test_given_invalidIndex_when_editFieldCalled_then_noChangesAreMade() {
        // Given: An invalid index and a custom field UI
        let editedField = CustomFieldsListViewModel.CustomFieldUI(key: "EditedKey1", value: "EditedValue1", id: 1)

        // When: Trying to edit a field at an invalid index
        viewModel.editField(at: -1, newField: editedField)

        // Then: No changes should be made
        XCTAssertEqual(viewModel.combinedList.count, 2)
        XCTAssertEqual(viewModel.combinedList[0].key, "Key1")
        XCTAssertEqual(viewModel.combinedList[0].value, "Value1")
        XCTAssertEqual(viewModel.combinedList[1].key, "Key2")
        XCTAssertEqual(viewModel.combinedList[1].value, "Value2")
    }

    func test_given_duplicateKey_when_addFieldCalled_then_fieldIsAdded() {
        // Given: A new custom field UI with a duplicate key
        let newField = CustomFieldsListViewModel.CustomFieldUI(key: "Key1", value: "NewValue")

        // When: Adding the new field
        viewModel.addField(newField)

        // Then: The field should be added to the list
        XCTAssertEqual(viewModel.combinedList.count, 3)
        XCTAssertEqual(viewModel.combinedList.last?.key, "Key1")
        XCTAssertEqual(viewModel.combinedList.last?.value, "NewValue")
    }
}
