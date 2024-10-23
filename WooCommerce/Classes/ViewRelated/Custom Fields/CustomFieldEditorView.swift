import SwiftUI

struct CustomFieldEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var key: String
    @State private var value: String
    @State private var showRichTextEditor = false
    @State private var showingActionSheet = false

    private let initialKey: String
    private let initialValue: String
    private let isCreatingNewField: Bool
    private let isReadOnlyValue: Bool
    private let onSave: (String, String) -> Void
    private let onDelete: () -> Void

    private var hasUnsavedChanges: Bool {
        key != initialKey || value != initialValue
    }

    /// Initializer for custom field editor
    /// - Parameters:
    ///  - key: The key for the custom field
    ///  - value: The value for the custom field
    ///  - isReadOnlyValue: Whether the value is read-only or not. To be used if the value is not string but JSON.
    ///  - onSave: Closure to handle save action
    init(key: String,
         value: String,
         isReadOnlyValue: Bool = false,
         isCreatingNewField: Bool = false,
         onSave: @escaping (String, String) -> Void,
         onDelete: @escaping () -> Void = {}) {
        self._key = State(initialValue: key)
        self._value = State(initialValue: value)
        self.initialKey = key
        self.initialValue = value
        self.isReadOnlyValue = isReadOnlyValue
        self.isCreatingNewField = isCreatingNewField
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                // Key Input
                VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                    Text(Localization.keyLabel)
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()

                    TextField(Localization.keyPlaceholder, text: $key)
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()
                        .padding(insets: Layout.inputInsets)
                        .background(Color(.listForeground(modal: false)))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                        )
                        .cornerRadius(Layout.cornerRadius)
                }

                // Value Input
                VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                    HStack {
                        Text(Localization.valueLabel)
                            .foregroundColor(Color(.text))
                            .subheadlineStyle()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        if !isReadOnlyValue {
                            Picker(Localization.editorPickerLabel, selection: $showRichTextEditor) {
                                Text(Localization.editorPickerText).tag(false)
                                Text(Localization.editorPickerHTML).tag(true)
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    if showRichTextEditor {
                        AztecEditorView(content: $value)
                        .frame(minHeight: Layout.minimumEditorSize)
                        .clipped()
                        .padding(insets: Layout.inputInsets)
                        .background(Color(.listForeground(modal: false)))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                        )
                        .cornerRadius(Layout.cornerRadius)
                    } else {
                        TextEditor(text: isReadOnlyValue ? .constant(value) : $value)
                            .foregroundColor(Color(.text))
                            .subheadlineStyle()
                            .frame(minHeight: Layout.minimumEditorSize)
                            .padding(insets: Layout.inputInsets)
                            .background(Color(.listForeground(modal: false)))
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                            )
                            .cornerRadius(Layout.cornerRadius)
                    }
                }
            }
            .padding()
        }
        .background(Color(.listBackground))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel") // todo-13493: set String to be translatable
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        saveChanges()
                        dismiss()
                    } label: {
                        Text("Save") // todo-13493: set String to be translatable
                    }
                    .disabled(!hasUnsavedChanges)

                    Button(action: {
                        showingActionSheet = true
                    }, label: {
                        Image(systemName: "ellipsis")
                            .renderingMode(.template)
                    })
                    .confirmationDialog("More Options", isPresented: $showingActionSheet) {
                        actionSheetContent
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var actionSheetContent: some View {
        Button("Copy Key") { // todo-13493: set String to be translatable
            UIPasteboard.general.string = key
            // todo-13493: Show a notice that the key was copied
        }

        Button("Copy Value") { // todo-13493: set String to be translatable
            UIPasteboard.general.string = value
            // todo-13493: Show a notice that the value was copied
        }

        if !isCreatingNewField {
            Button(Localization.deleteButton, role: .destructive) {
                onDelete()
                dismiss()
            }
        }
    }

    private func saveChanges() {
        onSave(key, value)
    }
}

// MARK: Constants
private extension CustomFieldEditorView {
    enum Layout {
        static let sectionSpacing: CGFloat = 16
        static let subSectionsSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let inputInsets = EdgeInsets(top: 8, leading: 5, bottom: 8, trailing: 5)
        static let minimumEditorSize: CGFloat = 400
    }

    enum Localization {
        static let keyLabel = NSLocalizedString(
            "customFieldEditorView.keyLabel",
            value: "Key",
            comment: "Label for the Key field"
        )

        static let keyPlaceholder = NSLocalizedString(
            "customFieldEditorView.keyPlaceholder",
            value: "Enter key",
            comment: "Placeholder for the Key field"
        )

        static let valueLabel = NSLocalizedString(
            "customFieldEditorView.valueLabel",
            value: "Value",
            comment: "Label for the Value field"
        )

        static let editorPickerLabel = NSLocalizedString(
            "customFieldEditorView.editorPickerLabel",
            value: "Choose text editing mode",
            comment: "Label for the Editor type picker"
        )

        static let editorPickerText = NSLocalizedString(
            "customFieldEditorView.editorPickerText",
            value: "Text",
            comment: "Picker option for using Text Editor"
        )

        static let editorPickerHTML = NSLocalizedString(
            "customFieldEditorView.editorPickerHTML",
            value: "HTML",
            comment: "Picker option for using Text Editor"
        )

        static let deleteButton = NSLocalizedString(
            "customFieldEditorView.deleteButton",
            value: "Delete custom field",
            comment: "Button title for deleting a custom field"
        )
    }
}

#Preview {
    CustomFieldEditorView(key: "title", value: "value", onSave: { _, _ in }, onDelete: {})
}
