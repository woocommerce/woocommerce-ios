import Combine
import Foundation
import Networking
import Yosemite

final class CustomFieldsListViewModel: ObservableObject {
    private let stores: StoresManager
    @Published private var originalCustomFields: [CustomFieldViewModel]
    private let customFieldsType: MetaDataType
    private let siteId: Int64
    private let parentItemId: Int64

    @Published var selectedCustomField: CustomFieldUI? = nil
    @Published var isAddingNewField: Bool = false
    @Published var isSavingChanges: Bool = false

    @Published private(set) var combinedList: [CustomFieldUI] = []
    @Published var notice: Notice?

    @Published private var pendingChanges = PendingCustomFieldsChanges()
    private var editedFields: [CustomFieldUI] {
        get { pendingChanges.editedFields }
        set { pendingChanges = pendingChanges.copy(editedFields: newValue) }
    }
    private var addedFields: [CustomFieldUI] {
        get { pendingChanges.addedFields }
        set { pendingChanges = pendingChanges.copy(addedFields: newValue) }
    }
    private var deletedFieldIds: [Int64] {
        get { pendingChanges.deletedFieldIds }
        set { pendingChanges = pendingChanges.copy(deletedFieldIds: newValue) }
    }
    @Published private(set) var hasChanges: Bool = false

    init(customFields: [CustomFieldViewModel],
         siteID: Int64,
         parentItemID: Int64,
         customFieldType: MetaDataType,
         stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        self.originalCustomFields = customFields
        self.siteId = siteID
        self.parentItemId = parentItemID
        self.customFieldsType = customFieldType

        observePendingChanges()
    }
}

// MARK: - Items actions
extension CustomFieldsListViewModel {
    /// Params:
    /// - index: The index of field to be edited, taken from the `combinedList` array
    /// - newField: The new content for the custom field in question
    func editField(at index: Int, newField: CustomFieldUI) {
        guard index >= 0 && index < combinedList.count else {
            DDLogError("⛔️ Error: Invalid index for editing a custom field")
            return
        }

        let oldField = combinedList[index]
        if newField.fieldId == nil {
            // When editing a field that has no id yet, it means the field has only been added locally.
            editLocallyAddedField(oldField: oldField, newField: newField)
        } else {
            if let existingId = oldField.fieldId {
                editExistingField(idToEdit: existingId, newField: newField)
            } else {
                DDLogError("⛔️ Error: Trying to edit an existing field but it has no id. It might be the wrong field to edit.")
            }
        }
    }

    func addField(_ field: CustomFieldUI) {
        addedFields.append(field)
    }

    func deleteField(_ field: CustomFieldUI) {
        if let fieldId = field.fieldId {
            deletedFieldIds.append(fieldId)
        } else {
            // The deleted field is not yet saved on the server, so we remove it from the added fields
            addedFields.removeAll { $0.id == field.id }
        }

        notice = Notice(title: CustomFieldsListHostingController.Localization.deleteNoticeTitle,
                        feedbackType: .success,
                        actionTitle: CustomFieldsListHostingController.Localization.deleteNoticeUndo,
                        actionHandler: { [weak self] in
                            self?.undoDeletion(of: field)
                        })
    }

    func saveField(key: String, value: String, fieldId: Int64?) {
        let newField = CustomFieldUI(key: key, value: value, fieldId: fieldId)
        if let fieldId = fieldId {
            if let index = combinedList.firstIndex(where: { $0.fieldId == fieldId }) {
                editField(at: index, newField: newField)
            }
        } else {
            addField(newField)
        }
    }

    /// Save changes to the server, uses async/await
    @MainActor
    func saveChanges() async {
        isSavingChanges = true
        // Remove any existing notice before saving changes
        notice = nil

        do {
            let result = try await dispatchSavingChanges()
            originalCustomFields = result.map { CustomFieldViewModel(metadata: $0) }
            pendingChanges = PendingCustomFieldsChanges()
        } catch {
            notice = Notice(title: CustomFieldsListHostingController.Localization.saveErrorTitle,
                            message: CustomFieldsListHostingController.Localization.saveErrorMessage,
                            feedbackType: .error)
        }

        isSavingChanges = false
    }
}

private extension CustomFieldsListViewModel {
    func editLocallyAddedField(oldField: CustomFieldUI, newField: CustomFieldUI) {
        if let index = pendingChanges.addedFields.firstIndex(where: { $0.key == oldField.key }) {
            addedFields[index] = newField
        } else {
            // This shouldn't happen in normal flow, but logging just in case
            DDLogError("⛔️ Error: Trying to edit a locally added field that doesn't exist in addedFields")
        }
    }

    /// Checking by id when editing an existing field since existing fields will always have them.
    func editExistingField(idToEdit: Int64, newField: CustomFieldUI) {
        guard idToEdit == newField.fieldId else {
            DDLogError("⛔️ Error: Trying to edit existing field but supplied new id is different.")
            return
        }

        if let index = editedFields.firstIndex(where: { $0.fieldId == idToEdit }) {
            // Existing field has been locally edited, let's update it again
            editedFields[index] = newField
        } else {
            // First time the field is locally edited
            editedFields.append(newField)
        }
    }

    func undoDeletion(of field: CustomFieldUI) {
        if let fieldId = field.fieldId {
            deletedFieldIds.removeAll { $0 == fieldId }
        } else {
            addedFields.append(field)
        }
    }

    func observePendingChanges() {
        $pendingChanges
            .combineLatest($originalCustomFields)
            .map { (pendingChanges, originalFields) in
                return originalFields
                    .filter { field in !pendingChanges.deletedFieldIds.contains(where: { $0 == field.id }) }
                    .map { field in pendingChanges.editedFields.first(where: { $0.fieldId == field.id }) ?? CustomFieldUI(customField: field) }
                    + pendingChanges.addedFields
            }
            .assign(to: &$combinedList)

        $pendingChanges
            .map { $0.hasChanges }
            .assign(to: &$hasChanges)
    }

    @MainActor
    func dispatchSavingChanges() async throws -> [MetaData] {
        return try await withCheckedThrowingContinuation { continuation in
            let action = MetaDataAction.updateMetaData(siteID: siteId,
                                                       parentItemID: parentItemId,
                                                       metaDataType: customFieldsType,
                                                       metadata: pendingChanges.asJson()) { result in
                continuation.resume(with: result)
            }

            stores.dispatch(action)
        }
    }
}

extension CustomFieldsListViewModel {
    struct CustomFieldUI: Identifiable {
        let id = UUID()
        let key: String
        let value: String
        let fieldId: Int64?

        init(key: String, value: String, fieldId: Int64? = nil) {
            self.key = key
            self.value = value
            self.fieldId = fieldId
        }

        init(customField: CustomFieldViewModel) {
            self.key = customField.title
            self.value = customField.content
            self.fieldId = customField.id
        }
    }

    struct PendingCustomFieldsChanges {
        let editedFields: [CustomFieldUI]
        let addedFields: [CustomFieldUI]
        let deletedFieldIds: [Int64]

        var hasChanges: Bool {
            editedFields.isNotEmpty || addedFields.isNotEmpty || deletedFieldIds.isNotEmpty
        }

        init(editedFields: [CustomFieldUI] = [],
             addedFields: [CustomFieldUI] = [],
             deletedFieldIds: [Int64] = []) {
            self.editedFields = editedFields
            self.addedFields = addedFields
            self.deletedFieldIds = deletedFieldIds
        }

        func copy(editedFields: [CustomFieldUI]? = nil,
                  addedFields: [CustomFieldUI]? = nil,
                  deletedFieldIds: [Int64]? = nil) -> PendingCustomFieldsChanges {
            PendingCustomFieldsChanges(editedFields: editedFields ?? self.editedFields,
                                       addedFields: addedFields ?? self.addedFields,
                                       deletedFieldIds: deletedFieldIds ?? self.deletedFieldIds)
        }

        func asJson() -> [[String: Any?]] {
            func metaDataAsJson(_ field: CustomFieldUI) -> [String: Any] {
                var json: [String: Any] = [:]
                if let fieldId = field.fieldId {
                    json["id"] = fieldId
                }
                json["key"] = field.key
                json["value"] = field.value
                return json
            }

            var json: [[String: Any?]] = []
            json.append(contentsOf: editedFields.map { metaDataAsJson($0) })
            json.append(contentsOf: addedFields.map { metaDataAsJson($0) })
            json.append(contentsOf: deletedFieldIds.map {
                ["id": $0, "value": nil]
            })
            return json
        }
    }
}
