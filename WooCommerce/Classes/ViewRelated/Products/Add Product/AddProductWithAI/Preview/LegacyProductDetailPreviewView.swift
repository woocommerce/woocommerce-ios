import SwiftUI

/// View for previewing product details generated with AI.
///
struct LegacyProductDetailPreviewView: View {

    @ObservedObject private var viewModel: LegacyProductDetailPreviewViewModel
    @State private var isShowingErrorAlert: Bool = false

    private let onDismiss: () -> Void

    init(viewModel: LegacyProductDetailPreviewViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.blockVerticalSpacing) {
                VStack(alignment: .leading, spacing: Layout.contentPadding) {
                    // Title label.
                    Text(Localization.title)
                        .fontWeight(.bold)
                        .titleStyle()

                    // Subtitle label.
                    Text(Localization.subtitle)
                        .foregroundColor(.secondary)
                        .bodyStyle()
                }
                .padding(.bottom, Layout.titleBlockBottomSpacing)

                // Product name
                VStack(alignment: .leading, spacing: Layout.contentVerticalSpacing) {
                    Text(Localization.productName)
                        .foregroundColor(.primary)
                        .subheadlineStyle()
                    BasicDetailRow(content: viewModel.productName,
                                   isLoading: viewModel.isGeneratingDetails)
                }

                // Product short description
                VStack(alignment: .leading, spacing: Layout.contentVerticalSpacing) {
                    Text(Localization.productShortDescription)
                        .foregroundColor(.primary)
                        .subheadlineStyle()
                    BasicDetailRow(content: viewModel.productShortDescription,
                                   isLoading: viewModel.isGeneratingDetails)
                }
                .renderedIf(viewModel.shouldShowShortDescriptionView)

                // Product description
                VStack(alignment: .leading, spacing: Layout.contentVerticalSpacing) {
                    Text(Localization.productDescription)
                        .foregroundColor(.primary)
                        .subheadlineStyle()
                    BasicDetailRow(content: viewModel.productDescription,
                                   isLoading: viewModel.isGeneratingDetails)
                }

                // Other details
                VStack(alignment: .leading, spacing: Layout.contentVerticalSpacing) {
                    Text(Localization.details)
                        .foregroundColor(.primary)
                        .subheadlineStyle()

                    // Product type
                    TitleAndValueDetailRow(title: Localization.productType,
                                           value: viewModel.productType,
                                           image: UIImage.productImage,
                                           isLoading: viewModel.isGeneratingDetails,
                                           cornerRadius: Layout.cornerRadius)
                    .padding(.bottom, Layout.contentPadding)

                    VStack(spacing: Layout.separatorHeight) {
                        // Price
                        TitleAndValueDetailRow(title: Localization.price,
                                               value: viewModel.productPrice,
                                               image: UIImage.priceImage,
                                               isLoading: viewModel.isGeneratingDetails)

                        // Inventory
                        TitleAndValueDetailRow(title: Localization.inventory,
                                               value: Localization.inStock,
                                               image: UIImage.inventoryImage,
                                               isLoading: viewModel.isGeneratingDetails)

                        // Categories
                        TitleAndValueDetailRow(title: Localization.categories,
                                               value: viewModel.productCategories,
                                               image: UIImage.categoriesIcon,
                                               isLoading: viewModel.isGeneratingDetails)

                        // Tags
                        TitleAndValueDetailRow(title: Localization.tags,
                                               value: viewModel.productTags,
                                               image: UIImage.tagsIcon,
                                               isLoading: viewModel.isGeneratingDetails)

                        // Shipping details
                        TitleAndValueDetailRow(title: Localization.shipping,
                                               value: viewModel.productShippingDetails,
                                               image: UIImage.shippingImage,
                                               isLoading: viewModel.isGeneratingDetails)
                    }
                    .background(viewModel.isGeneratingDetails ? Color.clear : Color(.separator))
                    .cornerRadius(Layout.cornerRadius)
                }

                // Feedback banner
                FeedbackView(title: Localization.feedbackQuestion,
                             backgroundColor: .init(uiColor: .init(light: .withColorStudio(.wooCommercePurple, shade: .shade0),
                                                                   dark: .tertiarySystemBackground)),
                             onVote: { vote in
                    withAnimation {
                        viewModel.handleFeedback(vote)
                    }
                })
                .renderedIf(viewModel.shouldShowFeedbackView)
            }
            .padding(insets: Layout.insets)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isGeneratingDetails || viewModel.isSavingProduct {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    } else {
                        Button(Localization.saveAsDraft) {
                            Task {
                                await viewModel.saveProductAsDraft()
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.generateProductDetails()
                }
            }
            .onChange(of: viewModel.errorState) { newValue in
                isShowingErrorAlert = newValue != .none
            }
            .alert(viewModel.errorState.errorMessage, isPresented: $isShowingErrorAlert) {
                Button(Localization.retry) {
                    Task {
                        switch viewModel.errorState {
                        case .none:
                            return
                        case .generatingProduct:
                            await viewModel.generateProductDetails()
                        case .savingProduct:
                            await viewModel.saveProductAsDraft()
                        }
                    }
                }
                Button(Localization.cancel, action: onDismiss)
            }
        }
    }
}

// MARK: - Subtypes
private extension LegacyProductDetailPreviewView {
    /// View to contain basic product details
    struct BasicDetailRow: View {
        let content: String?
        let isLoading: Bool
        let dummyText = Constants.dummyText

        typealias Layout = LegacyProductDetailPreviewView.Layout
        typealias Constants = LegacyProductDetailPreviewView.Constants

        var body: some View {
            Text(content ?? dummyText)
                .bodyStyle()
                .multilineTextAlignment(.leading)
                .padding(Layout.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Constants.detailRowColor)
                .cornerRadius(Layout.cornerRadius)
                .redacted(reason: isLoading ? .placeholder : [])
                .shimmering(active: isLoading)
        }
    }

    /// View to contain product details with title, value and image.
    struct TitleAndValueDetailRow: View {
        let title: String
        let value: String?
        let image: UIImage
        let isLoading: Bool
        var cornerRadius: CGFloat = 0
        let dummyText = Constants.dummyText

        typealias Layout = LegacyProductDetailPreviewView.Layout
        typealias Constants = LegacyProductDetailPreviewView.Constants

        var body: some View {
            HStack(alignment: .top, spacing: Layout.contentPadding) {
                Image(uiImage: image)
                    .renderingMode(.template)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: Layout.detailVerticalSpacing) {
                    Text(title)
                        .bodyStyle()
                    Text(value ?? dummyText)
                        .subheadlineStyle()
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(Layout.contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Constants.detailRowColor)
            .cornerRadius(cornerRadius)
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
            .renderedIf(isLoading || value != nil)
        }
    }
}

fileprivate extension LegacyProductDetailPreviewView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)
        static let titleBlockBottomSpacing: CGFloat = 24
        static let blockVerticalSpacing: CGFloat = 24
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let detailVerticalSpacing: CGFloat = 4
        static let separatorHeight: CGFloat = 0.5
    }
    enum Constants {
        static let dummyText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
        static let detailRowColor = Color(.init(light: .systemGray6, dark: .tertiarySystemBackground))
    }
    enum Localization {
        static let title = NSLocalizedString(
            "Preview",
            comment: "Title on the add product with AI Preview screen."
        )
        static let subtitle = NSLocalizedString(
            "You can always change the below details later.",
            comment: "Subtitle on the add product with AI Preview screen."
        )
        static let feedbackQuestion = NSLocalizedString(
            "Is the result helpful?",
            comment: "Question to ask for feedback for the AI-generated content on the add product with AI Preview screen."
        )
        static let productName = NSLocalizedString(
            "Product name",
            comment: "Title of the name field on the add product with AI Preview screen."
        )
        static let productShortDescription = NSLocalizedString(
            "Product short description",
            comment: "Title of the short description field on the add product with AI Preview screen."
        )
        static let productDescription = NSLocalizedString(
            "Product description",
            comment: "Title of the description field on the add product with AI Preview screen."
        )
        static let details = NSLocalizedString(
            "Details",
            comment: "Title of the details field on the add product with AI Preview screen."
        )
        static let productType = NSLocalizedString(
            "Product type",
            comment: "Title of the product type field on the add product with AI Preview screen."
        )
        static let price = NSLocalizedString(
            "Price",
            comment: "Title of the price field on the add product with AI Preview screen."
        )
        static let inventory = NSLocalizedString(
            "Inventory",
            comment: "Title of the inventory field on the add product with AI Preview screen."
        )
        static let inStock = NSLocalizedString(
            "In stock",
            comment: "Value of the inventory field on the add product with AI Preview screen."
        )
        static let categories = NSLocalizedString(
            "Categories",
            comment: "Title of the categories field on the add product with AI Preview screen."
        )
        static let tags = NSLocalizedString(
            "Tags",
            comment: "Title of the tags field on the add product with AI Preview screen."
        )
        static let shipping = NSLocalizedString(
            "Shipping",
            comment: "Title of the shipping field on the add product with AI Preview screen."
        )
        static let saveAsDraft = NSLocalizedString(
            "Save as draft",
            comment: "Button to save product details on the add product with AI Preview screen."
        )
        static let cancel = NSLocalizedString("Cancel", comment: "Button on the error alert displayed on the add product with AI Preview screen.")
        static let retry = NSLocalizedString("Retry", comment: "Button on the error alert displayed on the add product with AI Preview screen.")
    }
}


struct LegacyProductDetailPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        LegacyProductDetailPreviewView(viewModel: .init(siteID: 123,
                                                        productName: "iPhone 15",
                                                        productDescription: "New smart phone",
                                                        productFeatures: nil) { _ in },
                                       onDismiss: {})
    }
}
