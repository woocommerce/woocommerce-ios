import SwiftUI

struct CustomFieldEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: CustomFieldEditorViewModel

    @State private var showRichTextEditor = false
    @State private var showActionSheet = false

    private let isReadOnlyValue: Bool

    /// Initializer for custom field editor
    /// - Parameters:
    ///  - viewModel: The viewModel for this View.
    ///  - isReadOnlyValue: Whether the value is read-only or not. To be used if the value is not string but JSON.
    init(viewModel: CustomFieldEditorViewModel, isReadOnlyValue: Bool = false) {
        self.viewModel = viewModel
        self.isReadOnlyValue = isReadOnlyValue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                // Key Input
                VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                    Text(Localization.keyLabel)
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()

                    TextField(Localization.keyPlaceholder, text: $viewModel.key)
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()
                        .padding(insets: Layout.inputInsets)
                        .background(Color(.listForeground(modal: false)))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                                .stroke(viewModel.keyErrorMessage != nil ? Color(.error) : Color(.separator))
                        )
                        .cornerRadius(Layout.cornerRadius)

                    if let error = viewModel.keyErrorMessage {
                        Text(error)
                            .foregroundColor(Color(.error))
                            .font(.caption)
                    }
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
                            .onChange(of: showRichTextEditor) { newValue in
                                viewModel.trackEditorPickerTapped(showRichTextEditor: newValue)
                            }
                        }
                    }

                    if showRichTextEditor {
                        AztecEditorView(content: $viewModel.value)
                        .frame(minHeight: Layout.minimumEditorSize)
                        .clipped()
                        .padding(insets: Layout.inputInsets)
                        .background(Color(.listForeground(modal: false)))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                        )
                        .cornerRadius(Layout.cornerRadius)
                    } else {
                        TextEditor(text: isReadOnlyValue ? .constant(viewModel.value) : $viewModel.value)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        viewModel.saveChanges()
                        dismiss()
                    } label: {
                        Text(Localization.doneButton)
                    }
                    .disabled(!viewModel.hasUnsavedChanges || !viewModel.hasValidKey)

                    Button(action: {
                        showActionSheet = true
                    }, label: {
                        Image(systemName: "ellipsis")
                            .renderingMode(.template)
                    })
                    .confirmationDialog(Localization.actionSheetTitle, isPresented: $showActionSheet) {
                        actionSheetContent
                    }
                }
            }
        }
        .closeButtonWithDiscardChangesPrompt(hasChanges: viewModel.hasUnsavedChanges,
                                             closeButtonLabel: { Text(Localization.cancelButton) })
        .notice($viewModel.notice)
        .onAppear {
            viewModel.trackEditorViewLoaded()
        }
    }

    @ViewBuilder
    private var actionSheetContent: some View {
        Button(Localization.copyKeyButton) {
            UIPasteboard.general.string = viewModel.key
            viewModel.notice = Notice(title: Localization.keyCopiedNotice)
        }

        Button(Localization.copyValueButton) {
            UIPasteboard.general.string = viewModel.value
            viewModel.notice = Notice(title: Localization.valueCopiedNotice)
        }

        if viewModel.showDeleteButton {
            Button(Localization.deleteButton, role: .destructive) {
                viewModel.deleteField()
                dismiss()
            }
        }
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
        static let cancelButton = NSLocalizedString(
            "customFieldEditorView.cancel",
            value: "Cancel",
            comment: "Label for the Cancel button to close the editor"
        )

        static let doneButton = NSLocalizedString(
            "customFieldEditorView.done",
            value: "Done",
            comment: "Label for the Done button to save changes"
        )

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

        static let actionSheetTitle = NSLocalizedString(
            "customFieldEditorView.actionSheetTitle",
            value: "More Options",
            comment: "Title for the action sheet with additional options"
        )

        static let copyKeyButton = NSLocalizedString(
            "customFieldEditorView.copyKeyButton",
            value: "Copy Key",
            comment: "Button title for copying the custom field key"
        )

        static let copyValueButton = NSLocalizedString(
            "customFieldEditorView.copyValueButton",
            value: "Copy Value",
            comment: "Button title for copying the custom field value"
        )

        static let keyCopiedNotice = NSLocalizedString(
            "customFieldEditorView.keyCopiedNotice",
            value: "Key copied to clipboard",
            comment: "Notice shown when the key has been copied to clipboard"
        )

        static let valueCopiedNotice = NSLocalizedString(
            "customFieldEditorView.valueCopiedNotice",
            value: "Value copied to clipboard",
            comment: "Notice shown when the value has been copied to clipboard"
        )
    }
}

#Preview {
    CustomFieldEditorView(viewModel: CustomFieldEditorViewModel(key: "title", value: "value", onSave: { _, _ in }, onDelete: {}))
}
