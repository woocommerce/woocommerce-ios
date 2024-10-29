import Foundation

final class CustomFieldEditorViewModel: ObservableObject {
    @Published var key: String {
        didSet {
            validateKey(key)
        }
    }

    @Published var value: String
    @Published private(set) var keyErrorMessage: String?

    private let initialKey: String
    private let initialValue: String
    private let onSave: (String, String) -> Void

    /// Closure invoked during field deletion. Optional as it's not needed when creating a new field. Not private because it is used in the view for display logic.
    let onDelete: (() -> Void)?

    var hasUnsavedChanges: Bool {
        key != initialKey || value != initialValue
    }

    var hasValidKey: Bool {
        !key.isEmpty && !key.hasPrefix("_")
    }

    init(key: String,
         value: String,
         onSave: @escaping (String, String) -> Void,
         onDelete: (() -> Void)? = nil) {
        self.key = key
        self.value = value
        self.initialKey = key
        self.initialValue = value
        self.onSave = onSave
        self.onDelete = onDelete
    }

    func validateKey(_ newValue: String) {
        if newValue.hasPrefix("_") {
            keyErrorMessage = Localization.keyErrorPrefix
        } else {
            keyErrorMessage = nil
        }
    }

    func saveChanges() {
        onSave(key, value)
    }

    func deleteField() {
        onDelete?()
    }
}

// MARK: Constants
private extension CustomFieldEditorViewModel {
    enum Localization {
        static let keyErrorPrefix = NSLocalizedString(
            "customFieldEditorView.keyErrorPrefix",
            value: "Invalid key: please remove the '_' character from the beginning.",
            comment: "Error message shown when key starts with underscore"
        )
    }
}
