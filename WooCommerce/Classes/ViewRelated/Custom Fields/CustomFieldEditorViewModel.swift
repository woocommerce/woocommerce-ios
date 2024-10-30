import Foundation

final class CustomFieldEditorViewModel: ObservableObject {
    @Published var key: String {
        didSet {
            validateKey(key)
        }
    }

    @Published var value: String
    @Published private(set) var keyErrorMessage: String?

    /// To be set by the View
    @Published var notice: Notice?

    private let initialKey: String
    private let initialValue: String

    private let disallowedKeys: [String]

    private let onSave: (String, String) -> Void

    /// Closure invoked during field deletion. Optional as it's not needed when creating a new field.
    private let onDelete: (() -> Void)?

    var showDeleteButton: Bool {
        onDelete != nil
    }


    var hasUnsavedChanges: Bool {
        key != initialKey || value != initialValue
    }

    /// Note that `isEmpty` is validated separately, because we don't want to show error message when it's still empty, and instead just disable the button.
    var hasValidKey: Bool {
        !key.isEmpty && keyErrorMessage == nil
    }

    init(key: String,
         value: String,
         disallowedKeys: [String] = [],
         onSave: @escaping (String, String) -> Void,
         onDelete: (() -> Void)? = nil) {
        self.key = key
        self.value = value
        self.initialKey = key
        self.initialValue = value
        self.disallowedKeys = disallowedKeys
        self.onSave = onSave
        self.onDelete = onDelete
    }

    func validateKey(_ newValue: String) {
        if newValue.hasPrefix("_") {
            keyErrorMessage = Localization.keyErrorPrefix
        } else if disallowedKeys.first(where: { $0 == newValue }) != nil {
            keyErrorMessage = Localization.keyErrorDisallowedKey
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

        static let keyErrorDisallowedKey = NSLocalizedString(
            "customFieldEditorView.keyErrorDisallowedKey",
            value: "Invalid key: This key is already used for another custom field. \n" +
            "The app currently does not support creating duplicate keys. Please use wp-admin to duplicate a key if needed.",
            comment: "Error message shown when the entered key is identical to an existing key."
        )
    }
}
