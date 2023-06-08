import SwiftUI
import struct Yosemite.Product

/// Hosting controller for `ProductSharingMessageGenerationView`.
final class ProductSharingMessageGenerationHostingController: UIHostingController<ProductSharingMessageGenerationView> {
    init(viewModel: ProductSharingMessageGenerationViewModel,
         onShareMessage: @escaping (String) -> Void) {
        super.init(rootView: ProductSharingMessageGenerationView(viewModel: viewModel,
                                                                 onShareMessage: onShareMessage))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View for generating product sharing message with AI.
struct ProductSharingMessageGenerationView: View {
    @ObservedObject private var viewModel: ProductSharingMessageGenerationViewModel
    private let onShareMessage: (String) -> Void

    init(viewModel: ProductSharingMessageGenerationViewModel,
         onShareMessage: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onShareMessage = onShareMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.defaultSpacing) {

            Text(viewModel.viewTitle)
                .headlineStyle()

            Divider()

            // Generated message text field
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.messageContent)
                    .bodyStyle()
                    .foregroundColor(.secondary)
                    .background(viewModel.generationInProgress ? Color(uiColor: .buttonDisabledBackground) : .clear)
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
                    .renderedIf(viewModel.messageContent.isEmpty)
            }
            .renderedIf(viewModel.generationInProgress == false)

            // Skeleton view for loading state
            Text(Constants.dummyText)
                .secondaryBodyStyle()
                .padding(Constants.placeholderInsets)
                .background(RoundedRectangle(cornerRadius: Constants.cornerRadius).stroke(Color(uiColor: .secondarySystemFill)))
                .redacted(reason: .placeholder)
                .renderedIf(viewModel.generationInProgress)

            // Error message
            viewModel.errorMessage.map { message in
                Text(message).errorStyle()
            }

            Spacer()

            AdaptiveStack {
                Button(action: {
                    Task { @MainActor in
                        await viewModel.generateShareMessage()
                    }
                }, label: {
                    Label {
                        Text(viewModel.messageContent.isEmpty ? Localization.generate : Localization.regenerate)
                    } icon: {
                        Image(systemName: viewModel.messageContent.isEmpty ? "sparkles" : "arrow.counterclockwise")
                    }
                })
                .buttonStyle(SecondaryLoadingButtonStyle(isLoading: viewModel.generationInProgress))

                Button(Localization.shareMessage) {
                    onShareMessage(viewModel.messageContent)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(insets: Constants.insets)
    }
}

private extension ProductSharingMessageGenerationView {
    enum Constants {
        static let defaultSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)
        static let messageContentInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let placeholderInsets: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 16)
        static let dummyText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, " +
        "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, " +
        "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. " +
        "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
    }
    enum Localization {
        static let generate = NSLocalizedString(
            "Write it for me",
            comment: "Action button to generate message on the product sharing message generation screen"
        )
        static let regenerate = NSLocalizedString(
            "Regenerate",
            comment: "Action button to regenerate message on the product sharing message generation screen"
        )
        static let shareMessage = NSLocalizedString(
            "Share",
            comment: "Action button to share the generated message on the product sharing message generation screen"
        )
        static let placeholder = NSLocalizedString(
            "Add an optional message",
            comment: "Placeholder text on the product sharing message generation screen"
        )
    }
}

struct ProductSharingMessageGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        ProductSharingMessageGenerationView(viewModel: .init(siteID: 123,
                                                             productName: "Test",
                                                             url: "https://example.com"),
                                            onShareMessage: { _ in })
    }
}
