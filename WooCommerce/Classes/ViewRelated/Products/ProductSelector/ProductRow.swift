import SwiftUI

/// Represent a single product or variation row in the Product section of a New Order or in the ProductSelectorView
///
struct ProductRow: View {
    /// Whether more than one row can be selected.
    ///
    private let multipleSelectionsEnabled: Bool

    private let onCheckboxSelected: (() -> Void)?

    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: ProductRowViewModel

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1

    @Environment(\.isEnabled) private var isEnabled

    /// Accessibility hint describing the product row tap gesture.
    /// Avoids overwriting the product stepper accessibility hint, when the stepper is rendered.
    ///
    let accessibilityHint: String

    init(multipleSelectionsEnabled: Bool = false,
         viewModel: ProductRowViewModel,
         accessibilityHint: String = "",
         onCheckboxSelected: (() -> Void)? = nil) {
        self.multipleSelectionsEnabled = multipleSelectionsEnabled
        self.viewModel = viewModel
        self.accessibilityHint = accessibilityHint
        self.onCheckboxSelected = onCheckboxSelected
    }

    var body: some View {
        HStack(alignment: .center) {
            if multipleSelectionsEnabled {
                if let selectionHandler = onCheckboxSelected {
                    checkbox.onTapGesture {
                        selectionHandler()
                    }
                } else {
                    checkbox
                }
            }

            // Product image
            ProductImageThumbnail(productImageURL: viewModel.imageURL,
                                  productImageSize: Layout.productImageSize,
                                  scale: scale,
                                  productImageCornerRadius: Layout.cornerRadius,
                                  foregroundColor: Color(UIColor.listSmallIcon))

            // Product details
            VStack(alignment: .leading) {
                Text(viewModel.name)
                    .bodyStyle()
                Text(viewModel.productDetailsLabel)
                    .subheadlineStyle()
                    .renderedIf(viewModel.productDetailsLabel.isNotEmpty)
                    VStack(alignment: .leading) {
                        Text(viewModel.subscriptionConditionsLabel)
                            .subheadlineStyle()
                            .renderedIf(viewModel.subscriptionConditionsLabel.isNotEmpty)
                        Text(viewModel.subscriptionBillingDetailsLabel)
                            .font(.subheadline)
                            .foregroundColor(Color(.text))
                    }
                    .renderedIf(viewModel.shouldShowProductSubscriptionsDetails)
                Text(viewModel.secondaryProductDetailsLabel)
                    .subheadlineStyle()
                    .renderedIf(viewModel.secondaryProductDetailsLabel.isNotEmpty)
            }
            .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .opacity(viewModel.rowOpacity)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(viewModel.productAccessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var checkbox: some View {
        Image(uiImage: viewModel.selectedState.image)
            .resizable()
            .frame(width: Layout.checkImageSize * scale, height: Layout.checkImageSize * scale)
            .foregroundColor(isEnabled ? Color(.brand) : .gray)
    }
}

/// Subtype: SelectedState
///
extension ProductRow {
    enum SelectedState: Equatable {
        case notSelected
        case partiallySelected
        case selected
        case unsupported(reason: String)

        var image: UIImage {
            switch self {
            case .notSelected, .unsupported:
                return .checkEmptyCircleImage
            case .selected:
                return .checkCircleImage.withRenderingMode(.alwaysTemplate)
            case .partiallySelected:
                return .checkPartialCircleImage.withRenderingMode(.alwaysTemplate)
            }
        }
    }
}

private extension ProductRow {
    enum Layout {
        static let productImageSize: CGFloat = 48.0
        static let cornerRadius: CGFloat = 4.0
        static let checkImageSize: CGFloat = 24.0
    }
}

#if DEBUG
struct ProductRow_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProductRowViewModel(productOrVariationID: 1,
                                            name: "Love Ficus",
                                            sku: "123456",
                                            price: "20",
                                            stockStatusKey: "instock",
                                            stockQuantity: 7,
                                            manageStock: true,
                                            imageURL: nil,
                                            isConfigurable: true)
        let viewModelWithoutStepper = ProductRowViewModel(productOrVariationID: 1,
                                                          name: "Love Ficus",
                                                          sku: "123456",
                                                          price: "20",
                                                          stockStatusKey: "instock",
                                                          stockQuantity: 7,
                                                          manageStock: true,
                                                          imageURL: nil,
                                                          isConfigurable: false)

        ProductRow(viewModel: viewModel)
            .previewDisplayName("ProductRow with stepper")
            .previewLayout(.sizeThatFits)

        ProductRow(viewModel: viewModelWithoutStepper)
            .previewDisplayName("ProductRow without stepper")
            .previewLayout(.sizeThatFits)

        ProductRow(multipleSelectionsEnabled: true, viewModel: viewModelWithoutStepper)
            .previewDisplayName("ProductRow without stepper and with multiple selection")
            .previewLayout(.sizeThatFits)
    }
}
#endif
