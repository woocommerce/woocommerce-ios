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
    let isReadOnlyValue: Bool
    @State private var showRichTextEditor: Bool = false

    /// Initializer for custom field editor
    /// - Parameters:
    ///  - key: The key for the custom field
    ///  - value: The value for the custom field
    ///  - isReadOnlyValue: Whether the value is read-only or not. To be used if the value is not string but JSON.
    init(key: String, value: String, isReadOnlyValue: Bool = false) {
        self.isReadOnlyValue = isReadOnlyValue
        self._key = State(initialValue: key)
        self._value = State(initialValue: value)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    // Key Input
                    VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                        Text("Key")
                            .foregroundColor(Color(.text))
                            .subheadlineStyle()

                        TextField("Enter key", text: $key)
                            .bodyStyle()
                            .padding(insets: Layout.inputInsets)
                            .background(Color(.listForeground(modal: false)))
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                            )
                    }

                    // Value Input
                    VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                        Text("Value")
                            .foregroundColor(Color(.text))
                            .subheadlineStyle()

                        TextEditor(text: isReadOnlyValue ? .constant(value) : $value)
                            .bodyStyle()
                            .frame(minHeight: Layout.minimumEditorSize)
                            .padding(insets: Layout.inputInsets)
                            .background(Color(.listForeground(modal: false)))
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                            )
                    }
                }
                .padding()
            }

            // Rich Text Editor Button
            if !isReadOnlyValue {
                VStack {
                    Divider()

                    Button(action: {
                        showRichTextEditor = true
                    }) {
                        Text("Edit Value in Rich Text Editor")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
                }
                .background(Color(.listForeground(modal: false)))
            }

        }
        .background(Color(.listBackground))
        .sheet(isPresented: $showRichTextEditor) {
            // todo: do data handling in Aztec
            AztecEditorView(html: $value)
                .onDisappear {
                    // Handle any updates from rich text editor here
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
}

#Preview {
    CustomFieldEditorView(key: "title", value: "value")
}
