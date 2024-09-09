import Foundation

final class CustomFieldsListViewModel: ObservableObject {
    let customFields: [CustomFieldViewModel]

    var shouldShowErrorState: Bool {
        savingError != nil
    }

    @Published private(set) var savingError: Error?

    init(customFields: [CustomFieldViewModel]) {
        self.customFields = customFields
    }
}
