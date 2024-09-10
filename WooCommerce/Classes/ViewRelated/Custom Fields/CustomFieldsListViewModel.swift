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
        let oldField = combinedList[index]

        if newField.id == nil {
            // If there's no id, it means we're now editing a newly added field.
            if let addedIndex = addedFields.firstIndex(where: { $0.key == oldField.key }) {
                if newField.key == oldField.key {
                    // If the key hasn't changed, update the existing added field
                    addedFields[addedIndex] = newField
                } else {
                    // If the key has changed, remove the old field and add the new one
                    addedFields.remove(at: addedIndex)
                    addedFields.append(newField)
                }
            } else {
                // This case should not happen in normal flow
                DDLogError("⛔️ Error: Editing a newly updated field that doesn't exist in combinedList")

            }
        } else {
            // For when editing an already edited field
            if let editedIndex = editedFields.firstIndex(where: { $0.id == oldField.id }) {
                editedFields[editedIndex] = newField
            } else { 
                // For the first time a field is edited
                editedFields.append(newField)
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
