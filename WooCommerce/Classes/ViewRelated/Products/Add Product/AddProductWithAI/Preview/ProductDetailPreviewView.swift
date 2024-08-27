import SwiftUI

/// View for previewing product details generated with AI.
///
struct ProductDetailPreviewView: View {
    @ObservedObject private var viewModel: ProductDetailPreviewViewModel
    @State private var isShowingErrorAlert: Bool = false
    @FocusState private var focusedField: ProductDetailPreviewViewModel.EditableField?

    private let onDismiss: () -> Void

    init(viewModel: ProductDetailPreviewViewModel,
         onDismiss: @escaping () -> Void) {
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
                        .foregroundStyle(Color.secondary)
                        .bodyStyle()
                }

                // Product name and description
                VStack(alignment: .leading, spacing: Layout.contentVerticalSpacing) {
                    Text(Localization.nameSummaryAndDescription)
                        .foregroundStyle(Color.primary)
                        .headlineStyle()

                    // Product name
                    nameTextField

                    // Product short description
                    shortDescriptionTextField

                    // Product description
                    descriptionTextField

                    // Switch between options for product name and summary
                    summaryOptionsSwitch
                }

                // Package photo
                packagePhotoView

                // Other details
                VStack(alignment: .leading, spacing: Layout.contentVerticalSpacing) {
                    Text(Localization.details)
                        .foregroundStyle(Color.primary)
                        .headlineStyle()

                    // Product type
                    TitleAndValueDetailRow(title: Localization.productType,
                                           value: viewModel.productType,
                                           imageSystemName: "archivebox",
                                           isLoading: viewModel.isGeneratingDetails)
                    .roundedRectBorderStyle()


                    VStack(spacing: 0) {
                        // Price
                        TitleAndValueDetailRow(title: Localization.price,
                                               value: viewModel.productPrice,
                                               imageSystemName: "banknote",
                                               isLoading: viewModel.isGeneratingDetails)

                        SeparatorLine()

                        // Inventory
                        TitleAndValueDetailRow(title: Localization.inventory,
                                               value: Localization.inStock,
                                               imageSystemName: "list.number",
                                               isLoading: viewModel.isGeneratingDetails)

                        SeparatorLine()

                        // Categories
                        TitleAndValueDetailRow(title: Localization.categories,
                                               value: viewModel.productCategories,
                                               imageSystemName: "folder",
                                               isLoading: viewModel.isGeneratingDetails)

                        SeparatorLine()

                        // Tags
                        TitleAndValueDetailRow(title: Localization.tags,
                                               value: viewModel.productTags,
                                               imageSystemName: "tag",
                                               isLoading: viewModel.isGeneratingDetails)

                        SeparatorLine()

                        // Shipping details
                        TitleAndValueDetailRow(title: Localization.shipping,
                                               value: viewModel.productShippingDetails,
                                               imageSystemName: "truck.box",
                                               isLoading: viewModel.isGeneratingDetails)
                    }
                    .roundedRectBorderStyle()
                }

                feedbackBanner

                generateAgainButton
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
            .onDisappear {
                viewModel.onViewDisappear()
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
            .sheet(isPresented: $viewModel.isShowingViewPhotoSheet, content: {
                if case let .success(image) = viewModel.imageState {
                    ViewPackagePhoto(image: image.image, isShowing: $viewModel.isShowingViewPhotoSheet)
                }
            })
        }
        .notice($viewModel.notice)
    }
}

// MARK: - Private helper views
//
private extension ProductDetailPreviewView {
    var nameTextField: some View {
        UndoableTextField(placeholder: Localization.productNamePlaceholder,
                          content: $viewModel.productName,
                          isLoading: viewModel.isGeneratingDetails,
                          isFocused: focusedField == .name,
                          shouldEnableUndo: viewModel.hasChangesToProductName,
                          onUndoEdits: {
            viewModel.undoEdits(in: .name)
        })
        .focused($focusedField, equals: .name)
    }

    var shortDescriptionTextField: some View {
        UndoableTextField(placeholder: Localization.productShortDescriptionPlaceholder,
                          content: $viewModel.productShortDescription,
                          isLoading: viewModel.isGeneratingDetails,
                          isFocused: focusedField == .shortDescription,
                          shouldEnableUndo: viewModel.hasChangesToProductShortDescription,
                          onUndoEdits: {
            viewModel.undoEdits(in: .shortDescription)
        })
        .focused($focusedField, equals: .shortDescription)
    }

    var descriptionTextField: some View {
        UndoableTextField(placeholder: Localization.productDescriptionPlaceholder,
                          content: $viewModel.productDescription,
                          isLoading: viewModel.isGeneratingDetails,
                          isFocused: focusedField == .description,
                          shouldEnableUndo: viewModel.hasChangesToProductDescription,
                          onUndoEdits: {
            viewModel.undoEdits(in: .description)
        })
        .focused($focusedField, equals: .description)
    }

    var summaryOptionsSwitch: some View {
        HStack {
            Text(viewModel.optionsTitle)
                .secondaryBodyStyle()

            Spacer()

            OptionSwitchButton(isForward: false) {
                viewModel.switchToPreviousOption()
            }
            .disabled(!viewModel.canSelectPreviousOption)

            OptionSwitchButton(isForward: true) {
                viewModel.switchToNextOption()
            }
            .disabled(!viewModel.canSelectNextOption)
        }
        .padding(.top, Layout.contentVerticalSpacing)
        .renderedIf(viewModel.isGeneratingDetails == false && viewModel.canSwitchBetweenOptions)
    }

    var feedbackBanner: some View {
        FeedbackView(title: Localization.feedbackQuestion,
                     backgroundColor: Constants.feedbackViewColor,
                     onVote: { vote in
            withAnimation {
                viewModel.handleFeedback(vote)
            }
        })
        .renderedIf(viewModel.shouldShowFeedbackView)
    }

    var generateAgainButton: some View {
        Button {
            viewModel.didTapGenerateAgain()
        } label: {
            Text(Localization.generateAgain)
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(viewModel.isGeneratingDetails)
    }

    @ViewBuilder
    var packagePhotoView: some View {
        switch viewModel.imageState {
        case .empty:
            EmptyView()
        case .loading, .success:
            PackagePhotoView(title: Localization.photoSelected,
                             subTitle: Localization.addedToProduct,
                             imageState: viewModel.imageState,
                             onTapViewPhoto: {
                viewModel.didTapViewPhoto()
            },
                             onTapRemovePhoto: {
                viewModel.didTapRemovePhoto()
            })
        }
    }
}

// MARK: - Subtypes
//
private extension ProductDetailPreviewView {
    /// View to contain product details with title, value and image.
    struct TitleAndValueDetailRow: View {
        let title: String
        let value: String?
        let imageSystemName: String
        let isLoading: Bool
        let dummyText = Constants.dummyText

        typealias Constants = ProductDetailPreviewView.Constants

        @ScaledMetric private var scale: CGFloat = 1.0

        var body: some View {
            HStack(alignment: .imageTitleAlignmentGuide, spacing: ProductDetailPreviewView.Layout.contentPadding) {
                Image(systemName: imageSystemName)
                    .bodyStyle()
                    .alignmentGuide(.imageTitleAlignmentGuide) { context in
                        context[VerticalAlignment.center]
                    }

                VStack(alignment: .leading, spacing: Layout.detailVerticalSpacing) {
                    Text(title)
                        .bodyStyle()
                        .alignmentGuide(.imageTitleAlignmentGuide) { context in
                            context[VerticalAlignment.center]
                        }
                    Text(value ?? dummyText)
                        .subheadlineStyle()
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(ProductDetailPreviewView.Layout.fieldInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
            .renderedIf(isLoading || value != nil)
        }

        private enum Layout {
            static let detailVerticalSpacing: CGFloat = 4
            static let imageSize: CGFloat = 28
        }
    }

    struct SeparatorLine: View {
        var body: some View {
            Divider()
                .frame(height: ProductDetailPreviewView.Layout.separatorHeight)
                .foregroundStyle(ProductDetailPreviewView.Constants.separatorColor)
        }
    }

    struct Title: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.largeTitle)
                .foregroundStyle(.white)
                .padding()
                .background(.blue)
                .clipShape(.rect(cornerRadius: 10))
        }
    }

    struct UndoableTextField: View {
        let placeholder: String
        @Binding var content: String

        let isLoading: Bool
        let isFocused: Bool
        let shouldEnableUndo: Bool
        let onUndoEdits: () -> Void

        var body: some View {
            VStack {
                TextField(placeholder,
                          text: $content,
                          axis: .vertical)
                .textFieldStyle(.plain)
                .padding(Layout.fieldInsets)

                if shouldEnableUndo {
                    Divider()
                        .frame(height: ProductDetailPreviewView.Layout.borderWidth)
                        .foregroundStyle(Color.accentColor)

                    Button(action: onUndoEdits) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text(Localization.undoEdits)
                            Spacer()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                        .padding(Layout.fieldInsets)
                    }
                    .buttonStyle(.plain)
                }
            }
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
            .roundedRectBorderStyle(strokeColor: isFocused ? .accentColor : ProductDetailPreviewView.Constants.separatorColor)
        }
    }

    struct OptionSwitchButton: View {
        let isForward: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: isForward ? "chevron.forward" : "chevron.backward")
                    .fontWeight(.semibold)
                    .padding(Layout.fieldInsets)
                    .foregroundStyle(Color.accentColor)
                    .roundedRectBorderStyle()
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Rounded rect overlay
//
private struct RoundedBorder: ViewModifier {
    let strokeColor: Color

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: ProductDetailPreviewView.Layout.cornerRadius)
                    .stroke(strokeColor, lineWidth: ProductDetailPreviewView.Layout.borderWidth)
            )
    }
}

private extension View {
    func roundedRectBorderStyle(strokeColor: Color = ProductDetailPreviewView.Constants.separatorColor) -> some View {
        modifier(RoundedBorder(strokeColor: strokeColor))
    }
}

// MARK: - Constants
//
fileprivate extension ProductDetailPreviewView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let fieldInsets = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        static let blockVerticalSpacing: CGFloat = 24
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let separatorHeight: CGFloat = 0.5
        static let borderWidth: CGFloat = 1
    }

    enum Constants {
        static let dummyText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
        static let feedbackViewColor = Color(uiColor: .init(light: .withColorStudio(.wooCommercePurple, shade: .shade0),
                                                            dark: .tertiarySystemBackground))
        static let separatorColor = Color(.opaqueSeparator)
    }

    enum Localization {
        static let title = NSLocalizedString(
            "productDetailPreviewView.title",
            value: "Preview",
            comment: "Title on the add product with AI Preview screen."
        )
        static let subtitle = NSLocalizedString(
            "productDetailPreviewView.subtitle",
            value: "You can edit or regenerate your product details before saving.",
            comment: "Subtitle on the add product with AI Preview screen."
        )
        static let feedbackQuestion = NSLocalizedString(
            "productDetailPreviewView.feedbackQuestion",
            value: "Is this result good?",
            comment: "Question to ask for feedback for the AI-generated content on the add product with AI Preview screen."
        )
        static let nameSummaryAndDescription = NSLocalizedString(
            "productDetailPreviewView.nameSummaryAndDescription",
            value: "Name, Summary & Description",
            comment: "Title of the name, short description and description fields on the add product with AI Preview screen."
        )
        static let productNamePlaceholder = NSLocalizedString(
            "productDetailPreviewView.productNamePlaceholder",
            value: "Name your product",
            comment: "Placeholder text for the product name field on on the add product with AI Preview screen."
        )
        static let productShortDescriptionPlaceholder = NSLocalizedString(
            "productDetailPreviewView.productShortDescriptionPlaceholder",
            value: "A brief excerpt about your product",
            comment: "Placeholder text for the product short description field on the add product with AI Preview screen."
        )
        static let productDescriptionPlaceholder = NSLocalizedString(
            "productDetailPreviewView.productDescriptionPlaceholder",
            value: "Describe your product",
            comment: "Placeholder text for the product description field on the add product with AI Preview screen."
        )
        static let details = NSLocalizedString(
            "productDetailPreviewView.details",
            value: "Details",
            comment: "Title of the details field on the add product with AI Preview screen."
        )
        static let productType = NSLocalizedString(
            "productDetailPreviewView.productType",
            value: "Product type",
            comment: "Title of the product type field on the add product with AI Preview screen."
        )
        static let price = NSLocalizedString(
            "productDetailPreviewView.price",
            value: "Price",
            comment: "Title of the price field on the add product with AI Preview screen."
        )
        static let inventory = NSLocalizedString(
            "productDetailPreviewView.inventory",
            value: "Inventory",
            comment: "Title of the inventory field on the add product with AI Preview screen."
        )
        static let inStock = NSLocalizedString(
            "productDetailPreviewView.inStock",
            value: "In stock",
            comment: "Value of the inventory field on the add product with AI Preview screen."
        )
        static let categories = NSLocalizedString(
            "productDetailPreviewView.categories",
            value: "Categories",
            comment: "Title of the categories field on the add product with AI Preview screen."
        )
        static let tags = NSLocalizedString(
            "productDetailPreviewView.tags",
            value: "Tags",
            comment: "Title of the tags field on the add product with AI Preview screen."
        )
        static let shipping = NSLocalizedString(
            "productDetailPreviewView.shipping",
            value: "Shipping",
            comment: "Title of the shipping field on the add product with AI Preview screen."
        )
        static let saveAsDraft = NSLocalizedString(
            "productDetailPreviewView.saveAsDraft",
            value: "Save as draft",
            comment: "Button to save product details on the add product with AI Preview screen."
        )
        static let cancel = NSLocalizedString(
            "productDetailPreviewView.cancel",
            value: "Cancel",
            comment: "Button on the error alert displayed on the add product with AI Preview screen."
        )
        static let retry = NSLocalizedString(
            "productDetailPreviewView.retry",
            value: "Retry",
            comment: "Button on the error alert displayed on the add product with AI Preview screen."
        )
        static let generateAgain = NSLocalizedString(
            "productDetailPreviewView.generateAgain",
            value: "Generate Again",
            comment: "Button to regenerate AI product details again with AI Preview screen."
        )
        static let photoSelected = NSLocalizedString(
            "productDetailPreviewView.photoSelected",
            value: "Photo selected",
            comment: "Text to explain that a package photo has been selected in product preview screen."
        )
        static let addedToProduct = NSLocalizedString(
            "productDetailPreviewView.addedToProduct",
            value: "Photo will be added to product",
            comment: "Text to explain that a package photo has been selected in product preview screen."
        )
        static let undoEdits = NSLocalizedString(
            "productDetailPreviewView.undoEdits",
            value: "Undo edits",
            comment: "Button to undo edits for generated product name or summary in product preview screen."
        )
    }
}

// MARK: - Alignment guide
//
/// Used for aligning image and title in `TitleAndValueDetailRow`
///
private extension VerticalAlignment {
    /// A custom alignment for image titles.
    private struct ImageTitleAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            // Default to bottom alignment if no guides are set.
            context[VerticalAlignment.bottom]
        }
    }

    /// A guide for aligning titles.
    static let imageTitleAlignmentGuide = VerticalAlignment(
        ImageTitleAlignment.self
    )
}

// MARK: - Preview
//
struct ProductDetailPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDetailPreviewView(viewModel: .init(siteID: 123,
                                                  productFeatures: "Sample features",
                                                  imageState: .empty) { _ in },
                                 onDismiss: {})
    }
}
