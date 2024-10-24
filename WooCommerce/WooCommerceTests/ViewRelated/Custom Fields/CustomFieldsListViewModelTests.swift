import XCTest
@testable import WooCommerce
@testable import Networking
@testable import Yosemite

final class CustomFieldsListViewModelTests: XCTestCase {
    private let originalMetadata = [
            MetaData(metadataID: 1, key: "Key1", value: "Value1"),
            MetaData(metadataID: 2, key: "Key2", value: "Value2")
        ]
    private var originalFields: [CustomFieldViewModel] {
        originalMetadata.map(CustomFieldViewModel.init)
    }
    private let sampleSiteID: Int64 = 1
    private let sampleParentItemID: Int64 = 1
    private let sampleCustomFieldType = MetaDataType.product
    private var stores: MockStoresManager!

    private var viewModel: CustomFieldsListViewModel!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        viewModel = CustomFieldsListViewModel(customFields: originalFields,
                                              siteID: sampleSiteID,
                                              parentItemID: sampleParentItemID,
                                              customFieldType: sampleCustomFieldType,
                                              stores: stores)
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
        XCTAssertEqual(viewModel.combinedList[0].fieldId, 1)
        XCTAssertEqual(viewModel.combinedList[1].key, "Key2")
        XCTAssertEqual(viewModel.combinedList[1].value, "Value2")
        XCTAssertEqual(viewModel.combinedList[1].fieldId, 2)
    }

    func test_given_existingField_when_editFieldCalled_then_displayedItemsAndPendingChangesAreUpdated() {
        // Given: A custom field UI to edit an existing field
        let editedField = CustomFieldsListViewModel.CustomFieldUI(key: "EditedKey1", value: "EditedValue1", fieldId: 1)

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
        let editedField = CustomFieldsListViewModel.CustomFieldUI(key: "EditedKey1", value: "EditedValue1", fieldId: 1)
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

    func test_given_existingField_when_deleteFieldCalled_then_displayedItemsAndPendingChangesAreUpdated() {
        // Given: the field to delete
        let fieldToDelete = CustomFieldsListViewModel.CustomFieldUI(key: originalFields[0].title,
                                                                    value: originalFields[0].content,
                                                                    fieldId: originalFields[0].id)

        // When: Deleting the field
        viewModel.deleteField(fieldToDelete)

        // Then: The number of displayed items remains the same as before and the value is edited correctly
        XCTAssertEqual(viewModel.combinedList.count, 1)
        XCTAssertEqual(viewModel.combinedList[0].fieldId, originalFields[1].id)
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_given_newField_when_deleteFieldCalled_then_displayedItemsAndPendingChangesAreUpdated() {
        // Given: A new field to delete
        let newField = CustomFieldsListViewModel.CustomFieldUI(key: "NewKey", value: "NewValue")

        // When: Deleting the new field
        viewModel.addField(newField)
        viewModel.deleteField(newField)

        // Then: The displayed items should be updated
        XCTAssertEqual(viewModel.combinedList.count, 2)
        XCTAssertFalse(viewModel.hasChanges)
    }

    func test_given_variousChanges_when_pendingChangesUpdated_then_hasChangesReflectsCorrectState() {
        // Given: Initial state with no changes
        XCTAssertFalse(viewModel.hasChanges)

        // When: Editing a field
        let editedField = CustomFieldsListViewModel.CustomFieldUI(key: "EditedKey1", value: "EditedValue1", fieldId: 1)
        viewModel.editField(at: 0, newField: editedField)

        // Then: hasChanges should be true
        XCTAssertTrue(viewModel.hasChanges)

        // When: Adding a new field
        let newField = CustomFieldsListViewModel.CustomFieldUI(key: "NewKey", value: "NewValue")
        viewModel.addField(newField)

        // Then: hasChanges should be true
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_given_invalidIndex_when_editFieldCalled_then_noChangesAreMade() {
        // Given: An invalid index and a custom field UI
        let editedField = CustomFieldsListViewModel.CustomFieldUI(key: "EditedKey1", value: "EditedValue1", fieldId: 1)

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

    func test_given_saveFieldCalled_when_fieldExists_then_fieldIsUpdated() {
        // Given: An existing field to be updated
        let key = "UpdatedKey1"
        let value = "UpdatedValue1"
        let fieldId: Int64 = 1

        // When: Saving the field
        viewModel.saveField(key: key, value: value, fieldId: fieldId)

        // Then: The field should be updated in the list
        XCTAssertEqual(viewModel.combinedList.count, 2)
        XCTAssertEqual(viewModel.combinedList[0].key, "UpdatedKey1")
        XCTAssertEqual(viewModel.combinedList[0].value, "UpdatedValue1")
        XCTAssertEqual(viewModel.combinedList[0].fieldId, 1)
    }

    func test_given_saveFieldCalled_when_fieldDoesNotExist_then_fieldIsAdded() {
        // Given: A new field to be added
        let key = "NewKey"
        let value = "NewValue"
        let fieldId: Int64? = nil

        // When: Saving the field
        viewModel.saveField(key: key, value: value, fieldId: fieldId)

        // Then: The field should be added to the list
        XCTAssertEqual(viewModel.combinedList.count, 3)
        XCTAssertEqual(viewModel.combinedList.last?.key, "NewKey")
        XCTAssertEqual(viewModel.combinedList.last?.value, "NewValue")
        XCTAssertNil(viewModel.combinedList.last?.fieldId)
    }

    func test_given_savingSucceeds_when_saveChangesCalled_then_changesAreSaved() async {
        // Given: successfully saving the changes
        let newField = MetaData(metadataID: 10, key: "NewKey", value: "NewValue")
        stores.whenReceivingAction(ofType: MetaDataAction.self) { [self] action in
            switch action {
                case let .updateMetaData(_, _, _, _, onCompletion):
                    onCompletion(.success(originalMetadata + [newField]))
            }
        }

        // When: Saving the changes
        viewModel.saveField(key: newField.key, value: newField.value, fieldId: nil)
        await viewModel.saveChanges()

        // Then: The changes should be saved
        XCTAssertEqual(viewModel.combinedList.count, originalFields.count + 1)
        XCTAssertEqual(viewModel.combinedList.last?.key, newField.key)
        XCTAssertEqual(viewModel.combinedList.last?.value, newField.value)
        XCTAssertEqual(viewModel.combinedList.last?.fieldId, newField.metadataID)
        XCTAssertFalse(viewModel.hasChanges)
    }

    func test_given_savingFails_when_saveChangesCalled_then_changesAreNotSaved() async {
        // Given: failing to save the changes
        stores.whenReceivingAction(ofType: MetaDataAction.self) { action in
            switch action {
                case let .updateMetaData(_, _, _, _, onCompletion):
                    onCompletion(.failure(NetworkError.timeout()))
            }
        }

        // When: Saving the changes
        viewModel.saveField(key: "NewKey", value: "NewValue", fieldId: nil)
        await viewModel.saveChanges()

        // Then: The changes should not be saved
        XCTAssertEqual(viewModel.combinedList.count, originalFields.count + 1)
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_given_savingFails_when_saveChangesCalled_then_errorIsThrown() async {
        // Given: failing to save the changes
        stores.whenReceivingAction(ofType: MetaDataAction.self) { action in
            switch action {
                case let .updateMetaData(_, _, _, _, onCompletion):
                    onCompletion(.failure(NetworkError.timeout()))
            }
        }

        // When: Saving the changes
        viewModel.saveField(key: "NewKey", value: "NewValue", fieldId: nil)
        await viewModel.saveChanges()

        // Then: An error should be thrown
        XCTAssertNotNil(viewModel.notice)
    }
}
