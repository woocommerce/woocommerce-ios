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

    let isReadOnlyValue: Bool

    var hasUnsavedChanges: Bool {
        key != initialKey || value != initialValue
    }

    /// Note that `isEmpty` is validated separately, because we don't want to show error message when it's still empty, and instead just disable the button.
    var hasValidKey: Bool {
        !key.isEmpty && keyErrorMessage == nil
    }

    var isNewCreationMode: Bool {
        initialKey.isEmpty && initialValue.isEmpty
    }

    init(customField: CustomFieldViewModel?,
         disallowedKeys: [String] = [],
         onSave: @escaping (String, String) -> Void,
         onDelete: (() -> Void)? = nil) {
        self.key = customField?.key ?? ""
        self.initialKey = customField?.key ?? ""
        let value = if customField?.isJson == true, let value = customField?.value {
            value.prettyPrint()
        } else {
            customField?.value ?? ""
        }
        self.value = value
        self.initialValue = value
        self.isReadOnlyValue = customField?.isJson ?? false
        self.disallowedKeys = disallowedKeys
        self.onSave = onSave
        self.onDelete = onDelete
    }

    func validateKey(_ newValue: String) {
        if newValue.hasPrefix("_") {
            keyErrorMessage = Localization.keyErrorPrefix
        } else if disallowedKeys.contains(where: { $0 == newValue }) {
            keyErrorMessage = Localization.keyErrorDisallowedKey
        } else {
            keyErrorMessage = nil
        }
    }

    func saveChanges() {
        ServiceLocator.analytics.track(
            event: WooAnalyticsEvent.CustomFields.customFieldEditorDoneTapped()
        )
        onSave(key, value)
    }

    func deleteField() {
        ServiceLocator.analytics.track(
            event: WooAnalyticsEvent.CustomFields.customFieldEditorDeleteTapped()
        )
        onDelete?()
    }

    func trackEditorViewLoaded() {
        ServiceLocator.analytics.track(
            event: WooAnalyticsEvent.CustomFields.customFieldEditorLoaded(
                editorType: isNewCreationMode ?
                            WooAnalyticsEvent.CustomFields.EditorType.new :
                            WooAnalyticsEvent.CustomFields.EditorType.edit
            )
        )
    }

    func trackEditorPickerTapped(showRichTextEditor: Bool) {
        ServiceLocator.analytics.track(
            event: WooAnalyticsEvent.CustomFields.customFieldEditorPickerTapped(
                pickerType: showRichTextEditor ?
                WooAnalyticsEvent.CustomFields.EditorPicker.aztec :
                WooAnalyticsEvent.CustomFields.EditorPicker.text
            )
        )
    }
}

private extension String {
    func prettyPrint() -> String {
        return (try? JSONSerialization.jsonObject(with: self.data(using: .utf8) ?? Data()))
            .flatMap { try? JSONSerialization.data(withJSONObject: $0, options: .prettyPrinted) }
            .flatMap { String(data: $0, encoding: .utf8) }
            ?? self
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
