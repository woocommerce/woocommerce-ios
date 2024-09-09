import Foundation

final class CustomFieldsListViewModel: ObservableObject {
    private let customFields: [CustomFieldViewModel]

    var shouldShowErrorState: Bool {
        savingError != nil
    }

    @Published private(set) var savingError: Error?
    @Published var pendingChanges = PendingChanges()
    @Published var displayedItems: [CustomFieldUI]


    init(customFields: [CustomFieldViewModel]) {
        self.customFields = customFields

        self.displayedItems = customFields.map { item in
            CustomFieldUI(key: item.content, value: item.title, id: item.id)
        }
    }
}

private extension CustomFieldsListViewModel {
    func editField(_ field: CustomFieldUI) {
        if let index = pendingChanges.editedFields.firstIndex(where: { $0.id == field.id }) {
            pendingChanges.editedFields[index] = field
            updateDisplayedItems()
        }
    }

    func addField(_ field: CustomFieldUI) {
        pendingChanges.addedFields.append(field)
        updateDisplayedItems()
    }

    func updateDisplayedItems() {
        var updatedItems = displayedItems

        // Apply edits
        for editedField in pendingChanges.editedFields {
            if let index = updatedItems.firstIndex(where: { $0.id == editedField.id }) {
                updatedItems[index] = CustomFieldUI(key: editedField.key, value: editedField.value, id: editedField.id)
            }
        }

        // Add new fields
        updatedItems.append(contentsOf: pendingChanges.addedFields)

        displayedItems = updatedItems
    }
}

extension CustomFieldsListViewModel {
    struct PendingChanges {
        var editedFields: [CustomFieldUI] = []
        var addedFields: [CustomFieldUI] = []

        var hasChanges: Bool {
            !editedFields.isEmpty || !addedFields.isEmpty
        }
    }

    struct CustomFieldUI: Identifiable {
        let key: String
        let value: String
        let id: Int64?

        init(key: String, value: String, id: Int64? = nil) {
            self.key = key
            self.value = value
            self.id = id
        }
    }
}
