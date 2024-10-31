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
        XCTAssertEqual(viewModel.combinedList[0].fieldID, 1)
        XCTAssertEqual(viewModel.combinedList[1].key, "Key2")
        XCTAssertEqual(viewModel.combinedList[1].value, "Value2")
        XCTAssertEqual(viewModel.combinedList[1].fieldID, 2)
    }

    func test_given_existingField_when_editFieldCalled_then_displayedItemsAndPendingChangesAreUpdated() {
        // Given: A custom field UI to edit an existing field
        let editedField = CustomFieldViewModel(metadata: originalMetadata[0].copy(key: "EditedKey1", value: "EditedValue1"))

        // When: Editing the field
        viewModel.saveField(key: editedField.key, value: editedField.value, fieldID: editedField.fieldID)

        // Then: The number of displayed items remains the same as before and the value is edited correctly
        XCTAssertEqual(viewModel.combinedList.count, 2)
        XCTAssertEqual(viewModel.combinedList[0].key, "EditedKey1")
        XCTAssertEqual(viewModel.combinedList[0].value, "EditedValue1")
    }

    func test_given_newField_when_addFieldCalled_then_displayedItemsAndPendingChangesAreUpdated() {
        // Given: A new custom field UI to add
        let newField = CustomFieldViewModel(key: "NewKey", value: "NewValue")

        // When: Adding the new field
        viewModel.saveField(key: newField.key, value: newField.value, fieldID: nil)

        // Then: The pending changes and displayed items should be updated
        XCTAssertEqual(viewModel.combinedList.count, 3)
        XCTAssertEqual(viewModel.combinedList.last?.key, "NewKey")
        XCTAssertEqual(viewModel.combinedList.last?.value, "NewValue")
    }

    func test_given_editedAndNewFields_when_updatingDisplayedItems_then_changesAreReflected() {
        // Given: An edited field and a new field
        let editedField = CustomFieldViewModel(metadata: originalMetadata[0].copy(key: "EditedKey1", value: "EditedValue1"))
        let newField = CustomFieldViewModel(key: "NewKey", value: "NewValue")

        // When: Editing and adding fields
        viewModel.saveField(key: editedField.key, value: editedField.value, fieldID: editedField.fieldID)
        viewModel.saveField(key: newField.key, value: newField.value, fieldID: nil)

        // Then: The displayed items should reflect both the edited and added fields
        XCTAssertEqual(viewModel.combinedList.count, 3)
        XCTAssertEqual(viewModel.combinedList[0].key, "EditedKey1")
        XCTAssertEqual(viewModel.combinedList[0].value, "EditedValue1")
        XCTAssertEqual(viewModel.combinedList[2].key, "NewKey")
        XCTAssertEqual(viewModel.combinedList[2].value, "NewValue")
    }

    func test_given_existingField_when_deleteFieldCalled_then_displayedItemsAndPendingChangesAreUpdated() {
        // Given: the field to delete
        let fieldToDelete = CustomFieldViewModel(metadata: originalMetadata[0])

        // When: Deleting the field
        viewModel.deleteField(fieldToDelete)

        // Then: The number of displayed items remains the same as before and the value is edited correctly
        XCTAssertEqual(viewModel.combinedList.count, 1)
        XCTAssertEqual(viewModel.combinedList[0].fieldID, originalFields[1].fieldID)
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_given_newField_when_deleteFieldCalled_then_displayedItemsAndPendingChangesAreUpdated() {
        // Given: A new field to delete
        let newField = CustomFieldViewModel(key: "NewKey", value: "NewValue")

        // When: Deleting the new field
        viewModel.saveField(key: newField.key, value: newField.value, fieldID: nil)
        let fieldToDelete = viewModel.combinedList.last!
        viewModel.deleteField(fieldToDelete)

        // Then: The displayed items should be updated
        XCTAssertEqual(viewModel.combinedList.count, 2)
        XCTAssertFalse(viewModel.hasChanges)
    }

    func test_given_variousChanges_when_pendingChangesUpdated_then_hasChangesReflectsCorrectState() {
        // Given: Initial state with no changes
        XCTAssertFalse(viewModel.hasChanges)

        // When: Editing a field
        let editedField = CustomFieldViewModel(metadata: originalMetadata[0].copy(key: "EditedKey1", value: "EditedValue1"))
        viewModel.saveField(key: editedField.key, value: editedField.value, fieldID: editedField.fieldID)

        // Then: hasChanges should be true
        XCTAssertTrue(viewModel.hasChanges)

        // When: Adding a new field
        let newField = CustomFieldViewModel(key: "NewKey", value: "NewValue")
        viewModel.saveField(key: newField.key, value: newField.value, fieldID: nil)

        // Then: hasChanges should be true
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_given_duplicateKey_when_addFieldCalled_then_fieldIsAdded() {
        // Given: A new custom field UI with a duplicate key
        let newField = CustomFieldViewModel(key: "Key1", value: "NewValue")

        // When: Adding the new field
        viewModel.saveField(key: newField.key, value: newField.value, fieldID: nil)

        // Then: The field should be added to the list
        XCTAssertEqual(viewModel.combinedList.count, 3)
        XCTAssertEqual(viewModel.combinedList.last?.key, "Key1")
        XCTAssertEqual(viewModel.combinedList.last?.value, "NewValue")
    }

    func test_given_saveFieldCalled_when_fieldExists_then_fieldIsUpdated() {
        // Given: An existing field to be updated
        let key = "UpdatedKey1"
        let value = "UpdatedValue1"
        let fieldID: Int64 = 1

        // When: Saving the field
        viewModel.saveField(key: key, value: value, fieldID: fieldID)

        // Then: The field should be updated in the list
        XCTAssertEqual(viewModel.combinedList.count, 2)
        XCTAssertEqual(viewModel.combinedList[0].key, "UpdatedKey1")
        XCTAssertEqual(viewModel.combinedList[0].value, "UpdatedValue1")
        XCTAssertEqual(viewModel.combinedList[0].fieldID, 1)
    }

    func test_given_saveFieldCalled_when_fieldDoesNotExist_then_fieldIsAdded() {
        // Given: A new field to be added
        let key = "NewKey"
        let value = "NewValue"
        let fieldID: Int64? = nil

        // When: Saving the field
        viewModel.saveField(key: key, value: value, fieldID: fieldID)

        // Then: The field should be added to the list
        XCTAssertEqual(viewModel.combinedList.count, 3)
        XCTAssertEqual(viewModel.combinedList.last?.key, "NewKey")
        XCTAssertEqual(viewModel.combinedList.last?.value, "NewValue")
        XCTAssertNil(viewModel.combinedList.last?.fieldID)
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
        viewModel.saveField(key: newField.key, value: newField.value, fieldID: nil)
        await viewModel.saveChanges()

        // Then: The changes should be saved
        XCTAssertEqual(viewModel.combinedList.count, originalFields.count + 1)
        XCTAssertEqual(viewModel.combinedList.last?.key, newField.key)
        XCTAssertEqual(viewModel.combinedList.last?.value, newField.value)
        XCTAssertEqual(viewModel.combinedList.last?.fieldID, newField.metadataID)
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
        viewModel.saveField(key: "NewKey", value: "NewValue", fieldID: nil)
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
        viewModel.saveField(key: "NewKey", value: "NewValue", fieldID: nil)
        await viewModel.saveChanges()

        // Then: An error should be thrown
        XCTAssertNotNil(viewModel.notice)
    }

    func test_given_savingSucceeds_when_saveChangesCalled_then_callListener() async {
        // Given: successfully saving the changes
        stores.whenReceivingAction(ofType: MetaDataAction.self) { [self] action in
            switch action {
                case let .updateMetaData(_, _, _, _, onCompletion):
                    onCompletion(.success(originalMetadata))
            }
        }
        var listenerReceivedItems: [MetaData]? = nil
        viewModel = CustomFieldsListViewModel(customFields: originalFields,
                                              siteID: sampleSiteID,
                                              parentItemID: sampleParentItemID,
                                              customFieldType: sampleCustomFieldType,
                                              onChangesSaved: { listenerReceivedItems = $0 },
                                              stores: stores)
        // When: Saving the changes
        await viewModel.saveChanges()
        // Then: The listener should be called
        XCTAssertEqual(listenerReceivedItems, originalMetadata)
    }

    // MARK: - Disallowed Keys for Creation with local changes

    func test_given_originalAndAddedFields_then_disallowedKeysForCreationContainsAllKeys() {
        // Given: Original fields from setup and a new field
        let newField = CustomFieldViewModel(key: "NewKey", value: "NewValue")

        // When: Adding the new field
        viewModel.saveField(key: newField.key, value: newField.value, fieldID: nil)

        // Then: disallowedKeysForCreation should contain both original and new keys
        XCTAssertEqual(viewModel.disallowedKeysForCreation.count, 3)
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key1"))
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key2"))
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("NewKey"))
    }

    func test_given_editedFields_then_disallowedKeysForCreationStillContainsOriginalKeys() {
        // Given: Original fields and an edited field
        let editedField = CustomFieldViewModel(metadata: originalMetadata[0].copy(key: "EditedKey1", value: "EditedValue1"))

        // When: Editing a field (not yet saved remotely)
        viewModel.saveField(key: editedField.key, value: editedField.value, fieldID: editedField.fieldID)

        // Then: disallowedKeysForCreation should contain original keys since changes aren't saved
        XCTAssertEqual(viewModel.disallowedKeysForCreation.count, 2)
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key1"))
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key2"))
    }

    func test_given_deletedField_then_disallowedKeysForCreationStillContainsOriginalKey() {
        // Given: A field to delete
        let fieldToDelete = originalFields[0]

        // When: Deleting the field (not yet saved remotely)
        viewModel.deleteField(fieldToDelete)

        // Then: disallowedKeysForCreation should still contain all original keys since deletion isn't saved yet
        XCTAssertEqual(viewModel.disallowedKeysForCreation.count, 2)
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key1"))
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key2"))
    }

    func test_given_multipleChanges_then_disallowedKeysForCreationReflectsOriginalAndAddedKeys() {
        // Given: Original fields
        let editedField = CustomFieldViewModel(metadata: originalMetadata[0].copy(key: "EditedKey1", value: "EditedValue1"))
        let newField = CustomFieldViewModel(key: "NewKey", value: "NewValue")
        let fieldToDelete = originalFields[1]

        // When: Making multiple changes (not yet saved remotely)
        viewModel.saveField(key: editedField.key, value: editedField.value, fieldID: editedField.fieldID)
        viewModel.saveField(key: newField.key, value: newField.value, fieldID: nil)
        viewModel.deleteField(fieldToDelete)

        // Then: disallowedKeysForCreation should contain all original keys plus new keys
        XCTAssertEqual(viewModel.disallowedKeysForCreation.count, 3)
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key1"))
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key2"))
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("NewKey"))
    }

    // MARK: - Disallowed Keys for Creation with remote changes

    func test_given_addField_then_saveChanges_then_disallowedKeysUpdates() async {
        // Given: Initial state with two fields ("Key1", "Key2")

        let newMetadata = MetaData(metadataID: 3, key: "NewKey", value: "NewValue")
        let newField = CustomFieldViewModel(metadata: newMetadata)
        viewModel.saveField(key: newField.key, value: newField.value, fieldID: newField.fieldID)

        stores.whenReceivingAction(ofType: MetaDataAction.self) { [originalMetadata] action in
            switch action {
                case let .updateMetaData(_, _, _, _, onCompletion):
                    onCompletion(.success(originalMetadata + [newMetadata]))
            }
        }

        // When: Saving changes
        await viewModel.saveChanges()

        // Then: disallowedKeysForCreation includes the new saved field
        XCTAssertEqual(viewModel.disallowedKeysForCreation.count, 3)
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key1"))
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key2"))
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("NewKey"))
    }

    func test_given_saveField_then_saveChanges_then_disallowedKeysUpdates() async {
        // Given: Initial state with two fields ("Key1", "Key2")

        let editedMetadata = MetaData(metadataID: 1, key: "EditedKey1", value: "EditedValue1")
        viewModel.saveField(key: editedMetadata.key, value: editedMetadata.value, fieldID: editedMetadata.metadataID)

        stores.whenReceivingAction(ofType: MetaDataAction.self) { [originalMetadata] action in
            switch action {
                case let .updateMetaData(_, _, _, _, onCompletion):
                    let updatedMetadata = originalMetadata.map { $0.metadataID == 1 ? editedMetadata : $0 }
                    onCompletion(.success(updatedMetadata))
            }
        }

        // When: Saving changes
        await viewModel.saveChanges()

        // Then: disallowedKeysForCreation reflects the edited field
        XCTAssertEqual(viewModel.disallowedKeysForCreation.count, 2)
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("EditedKey1"))
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key2"))
    }

    func test_given_deleteField_then_saveChanges_then_disallowedKeysUpdates() async {
        // Given: Initial state with two fields ("Key1", "Key2")
        let fieldToDelete = originalFields[0]

        viewModel.deleteField(fieldToDelete)

        stores.whenReceivingAction(ofType: MetaDataAction.self) { [originalMetadata] action in
            switch action {
                case let .updateMetaData(_, _, _, _, onCompletion):
                    let updatedMetadata = originalMetadata.filter { $0.metadataID != fieldToDelete.fieldID }
                    onCompletion(.success(updatedMetadata))
            }
        }

        // When: Saving changes
        await viewModel.saveChanges()

        // Then: disallowedKeysForCreation excludes the deleted field
        XCTAssertEqual(viewModel.disallowedKeysForCreation.count, 1)
        XCTAssertFalse(viewModel.disallowedKeysForCreation.contains("Key1"))
        XCTAssertTrue(viewModel.disallowedKeysForCreation.contains("Key2"))
    }

    // MARK: - Top Banner
    func test_given_bannerNotDismissed_when_hasChanges_then_showBanner() async {
        // Given: The banner is not dismissed
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
                case let .loadCustomFieldsTopBannerDismissState(onCompletion):
                    onCompletion(false)
                default:
                    break
            }
        }
        viewModel = CustomFieldsListViewModel(customFields: originalFields,
                                              siteID: sampleSiteID,
                                              parentItemID: sampleParentItemID,
                                              customFieldType: sampleCustomFieldType,
                                              stores: stores)

        // When: Making changes
        viewModel.saveField(key: "NewKey", value: "NewValue", fieldID: nil)

        // Then: The banner should be shown
        XCTAssertTrue(viewModel.shouldShowTopBanner)
    }

    func test_given_bannerDismissed_when_hasChanges_then_hideBanner() async {
        // Given: The banner is dismissed
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
                case let .loadCustomFieldsTopBannerDismissState(onCompletion):
                    onCompletion(true)
                default:
                    break
            }
        }
        viewModel = CustomFieldsListViewModel(customFields: originalFields,
                                              siteID: sampleSiteID,
                                              parentItemID: sampleParentItemID,
                                              customFieldType: sampleCustomFieldType,
                                              stores: stores)

        // When: Making changes
        viewModel.saveField(key: "NewKey", value: "NewValue", fieldID: nil)

        // Then: The banner should not be shown
        XCTAssertFalse(viewModel.shouldShowTopBanner)
    }

    func test_given_bannerShown_when_dismissBannerCalled_then_bannerIsDismissed() async {
        // Given: The banner is shown
        var wasDismissed = false
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
                case let .loadCustomFieldsTopBannerDismissState(onCompletion):
                    onCompletion(false)
                case let .dismissCustomFieldsTopBanner(onCompletion):
                    wasDismissed = true
                    onCompletion(.success(()))
                default:
                    break
            }
        }

        // When: Dismissing the banner
        viewModel.dismissTopBanner()

        // Then: The banner should be dismissed
        XCTAssertTrue(wasDismissed)
	}
}
