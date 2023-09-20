import SwiftUI

/// View for adding product features in the product creation with AI flow.
///
struct AddProductFeaturesView: View {
    @FocusState private var editorIsFocused: Bool
    @ObservedObject private var viewModel: AddProductFeaturesViewModel

    init(viewModel: AddProductFeaturesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.blockBottomPadding) {
                VStack(alignment: .leading, spacing: Layout.titleBlockSpacing) {
                    // Title label.
                    Text(Localization.title)
                        .fontWeight(.bold)
                        .titleStyle()

                    // Subtitle label.
                    Text(Localization.subtitle)
                        .foregroundColor(Color(.secondaryLabel))
                        .bodyStyle()
                }

                VStack(alignment: .leading, spacing: Layout.editorBlockSpacing) {
                    Text(Localization.textFieldTitle)
                        .foregroundColor(Color(.label))
                        .subheadlineStyle()

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $viewModel.productFeatures)
                            .bodyStyle()
                            .foregroundColor(.secondary)
                            .padding(insets: Layout.textFieldContentInsets)
                            .frame(minHeight: Layout.minimumEditorHeight, maxHeight: .infinity)
                            .focused($editorIsFocused)

                        // Placeholder text
                        Text(Localization.placeholder)
                            .foregroundColor(Color(.placeholderText))
                            .bodyStyle()
                            .padding(insets: Layout.placeholderInsets)
                            // Allows gestures to pass through to the `TextEditor`.
                            .allowsHitTesting(false)
                            .renderedIf(viewModel.productFeatures.isEmpty)

                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(editorIsFocused ? Color(.brand) : Color(.separator))
                    )

                    Text(Localization.textFieldDescription)
                        .footnoteStyle()
                }

                Button(action: {
                    // TODO: show tone bottom sheet
                }, label: {
                    Text(Localization.setToneButton)
                        .foregroundColor(.accentColor)
                        .subheadlineStyle()
                })
                .buttonStyle(.plain)
            }
            .padding(insets: Layout.insets)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // CTA to continue to next screen.
                Button {
                    // TODO: start product detail generation
                    editorIsFocused = false
                } label: {
                    Text(Localization.continueText)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.productFeatures.isEmpty)
                .padding()
            }
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension AddProductFeaturesView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)

        static let blockBottomPadding: CGFloat = 40
        static let titleBlockSpacing: CGFloat = 16

        static let editorBlockSpacing: CGFloat = 8
        static let minimumEditorHeight: CGFloat = 70
        static let cornerRadius: CGFloat = 8
        static let textFieldContentInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let placeholderInsets: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 16)
    }
    enum Localization {
        static let title = NSLocalizedString(
            "About your product",
            comment: "Title on the add product features screen."
        )
        static let subtitle = NSLocalizedString(
            "Highlight what makes your product unique, and let AI do the magic.",
            comment: "Subtitle on the add product features screen."
        )
        static let textFieldTitle = NSLocalizedString(
            "My Product",
            comment: "Text field's label on the add product features screen."
        )
        static let placeholder = NSLocalizedString(
            "For example, Soft fabric, durable stitching, unique design",
            comment: "Placeholder text on the product features field"
        )
        static let textFieldDescription = NSLocalizedString(
            "Add key features, benefits, or details to help your product get found online.",
            comment: "Description for the text field on the add product features screen"
        )
        static let setToneButton = NSLocalizedString(
            "Set tone and voice",
            comment: "Button to select tone and voice for generating product details with AI"
        )
        static let continueText = NSLocalizedString(
            "Create Product Details",
            comment: "Continue button on the add product features screen"
        )
    }
}

struct AddProductDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductFeaturesView(viewModel: .init(siteID: 123, onProductDetailsCreated: {}))
    }
}
