import SwiftUI

/// View for previewing product details generated with AI.
///
struct ProductDetailPreviewView: View {

    @ObservedObject private var viewModel: ProductDetailPreviewViewModel

    init(viewModel: ProductDetailPreviewViewModel) {
        self.viewModel = viewModel
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
                    BasicDetailRow(content: viewModel.generatedProduct?.name,
                                   isLoading: viewModel.isGeneratingDetails)
                }

                // Product description
                VStack(alignment: .leading, spacing: Layout.contentVerticalSpacing) {
                    Text(Localization.productDescription)
                        .foregroundColor(.primary)
                        .subheadlineStyle()
                    BasicDetailRow(content: viewModel.generatedProduct?.fullDescription,
                                   isLoading: viewModel.isGeneratingDetails)
                }

                // TODO: update values based on product
                // Other details
                VStack(alignment: .leading, spacing: Layout.contentVerticalSpacing) {
                    Text(Localization.details)
                        .foregroundColor(.primary)
                        .subheadlineStyle()
                    TitleAndValueDetailRow(title: Localization.productType,
                                           value: "Physical",
                                           image: UIImage.productImage,
                                           isLoading: viewModel.isGeneratingDetails,
                                           cornerRadius: Layout.cornerRadius)
                    .padding(.bottom, Layout.contentPadding)

                    VStack(spacing: 0) {
                        TitleAndValueDetailRow(title: Localization.price,
                                               value: "Regular price: $15",
                                               image: UIImage.priceImage,
                                               isLoading: viewModel.isGeneratingDetails)
                        Divider()
                            .background(Color(.separator))
                        TitleAndValueDetailRow(title: Localization.inventory,
                                               value: Localization.inStock,
                                               image: UIImage.inventoryImage,
                                               isLoading: viewModel.isGeneratingDetails)
                        Divider()
                            .background(Color(.separator))
                        TitleAndValueDetailRow(title: Localization.categories,
                                               value: "Food, snack, sweet",
                                               image: UIImage.categoriesIcon,
                                               isLoading: viewModel.isGeneratingDetails)
                        Divider()
                            .background(Color(.separator))
                        TitleAndValueDetailRow(title: Localization.tags,
                                               value: "yummy, candy, chocolate",
                                               image: UIImage.tagsIcon,
                                               isLoading: viewModel.isGeneratingDetails)
                        Divider()
                            .background(Color(.separator))
                        TitleAndValueDetailRow(title: Localization.shipping,
                                               value: "Weight: 1kg\nDimension: 15 x 10 x 3 cm",
                                               image: UIImage.shippingImage,
                                               isLoading: viewModel.isGeneratingDetails)
                    }
                    .cornerRadius(Layout.cornerRadius)
                }

                // Feedback banner
                FeedbackView(title: Localization.feedbackQuestion,
                             backgroundColor: .init(uiColor: .init(light: .withColorStudio(.wooCommercePurple, shade: .shade0),
                                                                   dark: .tertiarySystemBackground)),
                             onVote: { vote in
                    viewModel.handleFeedback(vote)
                })
                .renderedIf(viewModel.isGeneratingDetails == false)
            }
            .padding(insets: Layout.insets)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isGeneratingDetails {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    } else {
                        Button(Localization.saveAsDraft) {
                            viewModel.saveProductAsDraft()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.generateProductDetails()
            }
        }
    }
}

// MARK: - Subtypes
private extension ProductDetailPreviewView {
    /// View to contain basic product details
    struct BasicDetailRow: View {
        let content: String?
        let isLoading: Bool
        let dummyText = Constants.dummyText

        typealias Layout = ProductDetailPreviewView.Layout
        typealias Constants = ProductDetailPreviewView.Constants

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

        typealias Layout = ProductDetailPreviewView.Layout
        typealias Constants = ProductDetailPreviewView.Constants

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
        }
    }
}

fileprivate extension ProductDetailPreviewView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)
        static let titleBlockBottomSpacing: CGFloat = 24
        static let blockVerticalSpacing: CGFloat = 24
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let detailVerticalSpacing: CGFloat = 4
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
            "Don't worry. You can always change those details later.",
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
    }
}


struct ProductDetailPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDetailPreviewView(viewModel: .init(siteID: 123))
    }
}
