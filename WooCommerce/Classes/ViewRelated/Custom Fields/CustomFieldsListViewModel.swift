import Foundation

final class CustomFieldsListViewModel: ObservableObject {
    private let originalCustomFields: [CustomFieldViewModel]

    var shouldShowErrorState: Bool {
        savingError != nil
    }

    @Published private(set) var savingError: Error?
    @Published private(set) var combinedList: [CustomFieldUI] = []

    @Published private var editedFields: [CustomFieldUI] = []
    @Published private var addedFields: [CustomFieldUI] = []
    var hasChanges: Bool {
        !editedFields.isEmpty || !addedFields.isEmpty
    }

    init(customFields: [CustomFieldViewModel]) {
        self.originalCustomFields = customFields
        updateCombinedList()
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
        if newField.id == nil {
            // When editing a field that has no id yet, it means the field has only been added locally.
            editLocallyAddedField(oldField: oldField, newField: newField)
        } else {
            if let existingId = oldField.id {
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
        guard idToEdit == newField.id else {
            DDLogError("⛔️ Error: Trying to edit existing field but supplied new id is different.")
            return
        }

        if let index = editedFields.firstIndex(where: { $0.id == idToEdit }) {
            // Existing field has been locally edited, let's update it again
            editedFields[index] = newField
        } else {
            // First time the field is locally edited
            editedFields.append(newField)
        }
    }

    func updateCombinedList() {
        let editedList = originalCustomFields.map { field in
            editedFields.first { $0.id == field.id } ?? CustomFieldUI(customField: field)
        }
        combinedList = editedList + addedFields
    }
}

extension CustomFieldsListViewModel {
    struct CustomFieldUI: Identifiable {
        let key: String
        let value: String
        let id: Int64?

        init(key: String, value: String, id: Int64? = nil) {
            self.key = key
            self.value = value
            self.id = id
        }

        init(customField: CustomFieldViewModel) {
            self.key = customField.title
            self.value = customField.content
            self.id = customField.id
        }
    }
}
