import SwiftUI
import struct Yosemite.Product

/// Hosting controller for `ProductSharingMessageGenerationView`.
final class ProductSharingMessageGenerationHostingController: UIHostingController<ProductSharingMessageGenerationView> {
    init(viewModel: ProductSharingMessageGenerationViewModel,
         onShareMessage: @escaping (String) -> Void,
         onDismiss: @escaping () -> Void,
         onSkip: @escaping () -> Void) {
        super.init(rootView: ProductSharingMessageGenerationView(viewModel: viewModel,
                                                                 onShareMessage: onShareMessage,
                                                                 onDismiss: onDismiss,
                                                                 onSkip: onSkip))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View for generating product sharing message with AI.
struct ProductSharingMessageGenerationView: View {
    @ObservedObject private var viewModel: ProductSharingMessageGenerationViewModel
    @State private var isRegeneratingMessage: Bool = false
    private let onShareMessage: (String) -> Void
    private let onDismiss: () -> Void
    private let onSkip: () -> Void

    init(viewModel: ProductSharingMessageGenerationViewModel,
         onShareMessage: @escaping (String) -> Void,
         onDismiss: @escaping () -> Void,
         onSkip: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onShareMessage = onShareMessage
        self.onDismiss = onDismiss
        self.onSkip = onSkip
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.defaultSpacing) {

            // Generated message text field
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.messageContent)
                    .bodyStyle()
                    .foregroundColor(.secondary)
                    .background(viewModel.generationInProgress ? Color(uiColor: .buttonDisabledBackground) : .clear)
                    .disabled(viewModel.generationInProgress)
                    .padding(insets: Layout.messageContentInsets)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                    )

                // Empty & loading state
                HStack {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    Text(Localization.generating)
                        .foregroundColor(Color(.placeholderText))
                        .bodyStyle()
                }
                .padding(insets: Layout.placeholderInsets)
                .frame(alignment: .center)
                .renderedIf(viewModel.messageContent.isEmpty && viewModel.generationInProgress)
            }

            // Error message
            viewModel.errorMessage.map { message in
                Text(message).errorStyle()
            }

            Spacer()

            Button(Localization.regenerate) {
                Task { @MainActor in
                    isRegeneratingMessage = true
                    await viewModel.generateShareMessage()
                    isRegeneratingMessage = false
                }
            }
            .buttonStyle(SecondaryLoadingButtonStyle(isLoading: isRegeneratingMessage))
            .renderedIf(viewModel.messageContent.isNotEmpty || viewModel.errorMessage != nil)

            Button(Localization.skip) {
                onSkip()
            }
            .buttonStyle(LinkButtonStyle())
        }
        .padding(insets: Layout.insets)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.viewTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.dismiss, action: onDismiss)
                    .foregroundColor(Color(.accent))
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(Localization.shareMessage) {
                    onShareMessage(viewModel.messageContent)
                }
                .foregroundColor(viewModel.messageContent.isEmpty ? Color.secondary : Color.accentColor)
                .disabled(viewModel.messageContent.isEmpty)
            }
        }
        .task {
            await viewModel.generateShareMessage()
        }
    }
}

private extension ProductSharingMessageGenerationView {
    enum Layout {
        static let defaultSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)
        static let messageContentInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let placeholderInsets: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 16)
    }
    enum Localization {
        static let generating = NSLocalizedString(
            "Generating share message...",
            comment: "Text showing the loading state of the product sharing message generation screen"
        )
        static let regenerate = NSLocalizedString(
            "Regenerate Message",
            comment: "Action button to regenerate message on the product sharing message generation screen"
        )
        static let shareMessage = NSLocalizedString(
            "Share",
            comment: "Action button to share the generated message on the product sharing message generation screen"
        )
        static let skip = NSLocalizedString(
            "Skip to share link only",
            comment: "Action button to skip the generated message on the product sharing message generation screen"
        )
        static let dismiss = NSLocalizedString("Dismiss", comment: "Button to dismiss the product sharing message generation screen")
    }
}

struct ProductSharingMessageGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        ProductSharingMessageGenerationView(viewModel: .init(siteID: 123,
                                                             productName: "Test",
                                                             url: "https://example.com"),
                                            onShareMessage: { _ in },
                                            onDismiss: {},
                                            onSkip: {})
    }
}
