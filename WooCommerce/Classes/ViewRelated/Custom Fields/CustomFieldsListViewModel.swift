import Combine
import Foundation

final class CustomFieldsListViewModel: ObservableObject {
    private let originalCustomFields: [CustomFieldViewModel]
    private let customFieldsType: MetaDataType

    var shouldShowErrorState: Bool {
        savingError != nil
    }

    @Published var selectedCustomField: CustomFieldUI? = nil
    @Published var isAddingNewField: Bool = false

    @Published private(set) var savingError: Error?
    @Published private(set) var combinedList: [CustomFieldUI] = []
    @Published var notice: Notice?

    @Published private var editedFields: [CustomFieldUI] = []
    @Published private var addedFields: [CustomFieldUI] = []
    @Published private var deletedFieldIds: [Int64] = []
    @Published private(set) var hasChanges: Bool = false

    init(customFields: [CustomFieldViewModel], customFieldType: MetaDataType) {
        self.originalCustomFields = customFields
        self.customFieldsType = customFieldType

        updateCombinedList()
        configureHasChanges()
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

        updateCombinedList()
    }

    func addField(_ field: CustomFieldUI) {
        addedFields.append(field)
        updateCombinedList()
    }

    func deleteField(_ field: CustomFieldUI) {
        if let fieldId = field.fieldId {
            deletedFieldIds.append(fieldId)
        } else {
            // The deleted field is not yet saved on the server, so we remove it from the added fields
            addedFields.removeAll { $0.id == field.id }
        }

        updateCombinedList()

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
}

private extension CustomFieldsListViewModel {
    func editLocallyAddedField(oldField: CustomFieldUI, newField: CustomFieldUI) {
        if let index = addedFields.firstIndex(where: { $0.key == oldField.key }) {
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

        updateCombinedList()
    }

    func updateCombinedList() {
        combinedList = originalCustomFields
            .filter { field in !deletedFieldIds.contains(where: { $0 == field.id }) }
            .map { field in editedFields.first(where: { $0.fieldId == field.id }) ?? CustomFieldUI(customField: field) }
            + addedFields
    }

    func configureHasChanges() {
        $editedFields.combineLatest($addedFields, $deletedFieldIds)
            .map { $0.isNotEmpty || $1.isNotEmpty || $2.isNotEmpty }
            .assign(to: &$hasChanges)
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
}
