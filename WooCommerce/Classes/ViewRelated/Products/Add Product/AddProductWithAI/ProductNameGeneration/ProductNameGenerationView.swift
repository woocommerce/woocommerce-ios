import SwiftUI

/// View for generating product name with AI.
///
struct ProductNameGenerationView: View {
    @ObservedObject private var viewModel: ProductNameGenerationViewModel

    init(viewModel: ProductNameGenerationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollableVStack(alignment: .leading, spacing: Constants.defaultSpacing) {

            // View title
            Text(Localization.title)
                .headlineStyle()

            Divider()

            // Generated message text field
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.messageContent)
                    .bodyStyle()
                    .foregroundColor(.secondary)
                    .disabled(viewModel.generationInProgress)
                    .opacity(viewModel.generationInProgress ? 0 : 1)
                    .padding(insets: Constants.messageContentInsets)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.cornerRadius).stroke(Color(.separator))
                    )

                // Placeholder text
                Text(Localization.placeholder)
                    .foregroundColor(Color(.placeholderText))
                    .bodyStyle()
                    .padding(insets: Constants.placeholderInsets)
                    // Allows gestures to pass through to the `TextEditor`.
                    .allowsHitTesting(false)
                    .renderedIf(viewModel.messageContent.isEmpty &&
                                viewModel.generationInProgress == false)
            }
            .overlay(
                VStack {
                    // Skeleton view for loading state
                    Text(Constants.dummyText)
                        .bodyStyle()
                        .redacted(reason: .placeholder)
                        .shimmering()
                        .padding(insets: Constants.placeholderInsets)
                        .renderedIf(viewModel.generationInProgress)
                    Spacer()
                }
            )

            // Error message
            viewModel.errorMessage.map { message in
                Text(message).errorStyle()
            }

            HStack(spacing: Constants.horizontalSpacing) {
                // Action button to generate message
                Button(action: {
                    // TODO
                }, label: {
                    Label {
                        Text(viewModel.generateButtonTitle)
                    } icon: {
                        Image(uiImage: viewModel.generateButtonImage)
                            .renderingMode(.template)
                    }
                })
                .buttonStyle(SecondaryLoadingButtonStyle(isLoading: viewModel.generationInProgress, loadingText: Localization.generateInProgress))

                Spacer()

                Button(Localization.apply) {
                    // TODO
                }
                .buttonStyle(PrimaryButtonStyle())
                .renderedIf(viewModel.hasGeneratedMessage)
            }
            .renderedIf(viewModel.generationInProgress == false)
        }
    }
}

private extension ProductNameGenerationView {
    enum Constants {
        static let defaultSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)
        static let messageContentInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let placeholderInsets: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 16)
        static let dummyText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit," +
        "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam," +
        "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat." +
        "nisi ut aliquip ex ea commodo consequat."
        static let dummyTextInsets: EdgeInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
        static let horizontalSpacing: CGFloat = 8
    }
    enum Localization {
        static let title = NSLocalizedString(
            "Product name",
            comment: "Title on the product title generation screen"
        )
        static let generateInProgress = NSLocalizedString(
            "Generating...",
            comment: "Text to show the loading state on the product title generation screen"
        )
        static let apply = NSLocalizedString(
            "Apply",
            comment: "Action button to apply the generated title for the new product"
        )
        static let detailDescription = NSLocalizedString(
            "For example, Soft fabric, durable stitching, unique design",
            comment: "Placeholder text on the product title generation screen"
        )
        static let placeholder = NSLocalizedString(
            "For example, Soft fabric, durable stitching, unique design",
            comment: "Placeholder text on the product title generation screen"
        )
    }
}

struct ProductNameAIBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        ProductNameGenerationView(viewModel: .init(siteID: 123))
    }
}
