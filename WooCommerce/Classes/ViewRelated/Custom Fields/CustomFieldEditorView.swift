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
    let isHtmlValue: Bool = true // todo replace with actual value

    // Showing example HTML for now
    @State private var key: String = "html"
    @State private var value: String = "<h1>My First Heading</h1><p>My first paragraph.</p><p>Some <strong>bold</strong></p>"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Enter key", text: $key)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(10)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Value")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isHtmlValue {
                    AztecEditorView(html: $value)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                else {
                    TextField("Enter value", text: $key)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
}

#Preview {
    CustomFieldEditorView()
}
