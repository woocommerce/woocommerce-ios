import SwiftUI
import struct Yosemite.Product

/// Hosting controller for `ProductSharingMessageGenerationView`.
final class ProductSharingMessageGenerationHostingController: UIHostingController<ProductSharingMessageGenerationView> {
    init(viewModel: ProductSharingMessageGenerationViewModel) {
        super.init(rootView: ProductSharingMessageGenerationView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View for generating product sharing message with AI.
struct ProductSharingMessageGenerationView: View {
    @ObservedObject private var viewModel: ProductSharingMessageGenerationViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var isShowingLegalPage = false
    private let legalURL = URL(string: "https://automattic.com/ai-guidelines/")

    private var shouldKeepGenerateButtonAtFixedSize: Bool {
        !dynamicTypeSize.isAccessibilitySize || horizontalSizeClass != .compact
    }

    init(viewModel: ProductSharingMessageGenerationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.defaultSpacing) {

            // View title
            Text(viewModel.viewTitle)
                .headlineStyle()

            Divider()

            // Generated message text field
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.messageContent)
                    .bodyStyle()
                    .foregroundColor(.secondary)
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
                .redacted(reason: .placeholder)
                .shimmering()
                .padding(Constants.placeholderInsets)
                .background(RoundedRectangle(cornerRadius: Constants.cornerRadius).stroke(Color(uiColor: .secondarySystemFill)))
                .renderedIf(viewModel.generationInProgress)

            // Error message
            viewModel.errorMessage.map { message in
                Text(message).errorStyle()
            }

            AdaptiveStack {
                // Action button to generate message
                Button(action: {
                    Task {
                        await viewModel.generateShareMessage()
                    }
                }, label: {
                    Label {
                        Text(viewModel.generateButtonTitle)
                    } icon: {
                        Image(uiImage: viewModel.generateButtonImage)
                            .renderingMode(.template)
                    }
                })
                .buttonStyle(SecondaryLoadingButtonStyle(isLoading: viewModel.generationInProgress, loadingText: Localization.generateInProgress))
                .fixedSize(horizontal: shouldKeepGenerateButtonAtFixedSize,
                           vertical: shouldKeepGenerateButtonAtFixedSize)

                // Button for more information about legal
                Button {
                    isShowingLegalPage = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }

            Spacer()

            Button(Localization.shareMessage) {
                viewModel.didTapShare()
            }
            .buttonStyle(PrimaryButtonStyle())
            .sharePopover(isPresented: $viewModel.isSharePopoverPresented) {
                viewModel.shareSheet
            }
            .shareSheet(isPresented: $viewModel.isShareSheetPresented) {
                viewModel.shareSheet
            }
            .safariSheet(isPresented: $isShowingLegalPage, url: legalURL)
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
        static let dummyText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit," +
        "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam," +
        "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
    }
    enum Localization {
        static let generateInProgress = NSLocalizedString(
            "Generating...",
            comment: "Text to show the loading state on the product sharing message generation screen"
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
                                                             url: "https://example.com",
                                                             productName: "Test",
                                                             productDescription: "Test product description"))
    }
}
