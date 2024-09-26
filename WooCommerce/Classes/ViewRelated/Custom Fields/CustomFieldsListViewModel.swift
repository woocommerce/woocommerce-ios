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
    func editField(at index: Int, newField: CustomFieldUI) {
        guard index >= 0 && index < combinedList.count else {
            DDLogError("⛔️ Error: Invalid index for editing a custom field")
            return
        }

        let oldField = combinedList[index]
        if newField.id == nil {
            editLocallyAddedField(oldField: oldField, newField: newField)
        } else {
            if let existingId = oldField.id {
                editExistingField(idToEdit: existingId, newField: newField)
            } else {
                DDLogError("⛔️ Error: Trying to edit existing field that has no id.")
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
            // Found the matching field, update it
            addedFields[index] = newField
        } else {
            // This shouldn't happen in normal flow, but log an error just in case
            DDLogError("⛔️ Error: Trying to edit a locally added field that doesn't exist in addedFields")
        }
    }

    func editExistingField(idToEdit: Int64, newField: CustomFieldUI) {
        guard idToEdit == newField.id else {
            DDLogError("⛔️ Error: Trying to edit existing field but supplied new id is different.")
            return
        }

        if let index = editedFields.firstIndex(where: { $0.id == idToEdit }) {
            // This field has been locally edited, let's update it again
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
