import SwiftUI

struct AztecEditorView: UIViewControllerRepresentable {
    @Binding var html: String

    func makeUIViewController(context: Context) -> AztecEditorViewController {
        let viewProperties = EditorViewProperties(navigationTitle: "Navigation title", /* todo replace string */
                                                  placeholderText: "placeholder text", /* todo replace string */
                                                  showSaveChangesActionSheet: true)

        let controller = AztecEditorViewController(
            content: html,
            product: nil,
            viewProperties: viewProperties,
            isAIGenerationEnabled: false
        )

        return controller
    }

    func updateUIViewController(_ uiViewController: AztecEditorViewController, context: Context) {
        // Update the view controller if needed
    }
}

struct CustomFieldEditorView: View {
    @State private var key: String
    @State private var value: String
    @State private var isModified: Bool = false
    @State private var showRichTextEditor: Bool = false

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
                    HStack {
                         Text("Value") // todo-13493: set String to be translatable
                             .foregroundColor(Color(.text))
                             .subheadlineStyle()

                         Spacer()

                         if !isReadOnlyValue {
                             Button(action: {
                                 showRichTextEditor = true
                             }) {
                                 Text("Edit in Rich Text Editor") // todo-13493: set String to be translatable
                                     .font(.footnote)
                             }
                             .buttonStyle(.plain)
                             .foregroundColor(Color(uiColor: .accent))
                         }
                     }

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
            .padding()
        }
        .background(Color(.listBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saveChanges()
                } label: {
                    Text("Save") // todo-13493: set String to be translatable
                }
                .disabled(!isModified)
            }
        }
        .sheet(isPresented: $showRichTextEditor) {
            // todo-13493: Aztec needs toolbar and change handling
            AztecEditorView(html: $value)
                .onDisappear {
                    checkForModifications()
                }
        }
    }

    private func checkForModifications() {
        isModified = key != initialKey || value != initialValue
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
