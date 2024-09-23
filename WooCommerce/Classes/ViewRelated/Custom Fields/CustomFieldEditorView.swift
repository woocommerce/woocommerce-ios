import SwiftUI

struct CustomFieldEditorView: View {
    @State private var key: String
    @State private var value: String
    @State private var hasUnsavedChanges: Bool = false
    @State private var showRichTextEditor: Bool = false
    @State private var showingActionSheet: Bool = false

    private let initialKey: String
    private let initialValue: String
    private let isReadOnlyValue: Bool


    /// Initializer for custom field editor
    /// - Parameters:
    ///  - key: The key for the custom field
    ///  - value: The value for the custom field
    ///  - isReadOnlyValue: Whether the value is read-only or not. To be used if the value is not string but JSON.
    init(key: String, value: String, isReadOnlyValue: Bool = false) {
        self._key = State(initialValue: key)
        self._value = State(initialValue: value)
        self.initialKey = key
        self.initialValue = value
        self.isReadOnlyValue = isReadOnlyValue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                // Key Input
                VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                    Text("Key") // todo-13493: set String to be translatable
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()

                    TextField("Enter key", text: $key) // todo-13493: set String to be translatable
                        .bodyStyle()
                        .padding(insets: Layout.inputInsets)
                        .background(Color(.listForeground(modal: false)))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                        )
                        .onChange(of: key) { _ in
                            checkForModifications()
                        }
                }

                // Value Input
                VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                    Text("Value") // todo-13493: set String to be translatable
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()

                    if !isReadOnlyValue {

                        Picker("Choose editing mode:", selection: $showRichTextEditor) {
                            Text("Text").tag(false)
                            Text("HTML").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                    if showRichTextEditor {
                        AztecEditorView(value: $value)
                        .frame(minHeight: Layout.minimumEditorSize)
                        .clipped()
                        .padding(insets: Layout.inputInsets)
                        .background(Color(.listForeground(modal: false)))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                        )
                    } else {
                        TextEditor(text: isReadOnlyValue ? .constant(value) : $value)
                            .bodyStyle()
                            .frame(minHeight: Layout.minimumEditorSize)
                            .padding(insets: Layout.inputInsets)
                            .background(Color(.listForeground(modal: false)))
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                            )
                            .onChange(of: value) { _ in
                                checkForModifications()
                            }
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
                        saveChanges()
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

        Button("Delete Custom Field", role: .destructive) { // todo-13493: set String to be translatable
            // todo-13493: Implement delete action
        }
    }

    private func checkForModifications() {
        hasUnsavedChanges = key != initialKey || value != initialValue
    }

    private func saveChanges() {
        // todo-13493: add save logic
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
}

#Preview {
    CustomFieldEditorView(key: "title", value: "value")
}
