import SwiftUI
import Kingfisher

/// Represent a single product or variation row in the Product section of a New Order or in the ProductSelector
///
struct ProductRow: View {
    /// Whether more than one row can be selected.
    ///
    private let multipleSelectionsEnabled: Bool

    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: ProductRowViewModel

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1

    /// Accessibility hint describing the product row tap gesture.
    /// Avoids overwriting the product stepper accessibility hint, when the stepper is rendered.
    ///
    let accessibilityHint: String

    /// Image processor to resize images in a background thread to avoid blocking the UI
    /// 
    ///
    private var imageProcessor: ImageProcessor {
        ResizingImageProcessor(
            referenceSize: .init(width: Layout.productImageSize * scale, height: Layout.productImageSize * scale),
            mode: .aspectFill)
    }

    init(multipleSelectionsEnabled: Bool = false, viewModel: ProductRowViewModel, accessibilityHint: String = "") {
        self.multipleSelectionsEnabled = multipleSelectionsEnabled
        self.viewModel = viewModel
        self.accessibilityHint = accessibilityHint
    }

    var body: some View {
        VStack {
            AdaptiveStack(horizontalAlignment: .leading) {
                HStack(alignment: .center) {
                    if multipleSelectionsEnabled {
                        Image(uiImage: viewModel.isSelected ? .checkCircleImage.withRenderingMode(.alwaysTemplate) : .checkEmptyCircleImage)
                            .frame(width: Layout.checkImageSize * scale, height: Layout.checkImageSize * scale)
                            .foregroundColor(.init(UIColor.brand))
                    }

                    // Product image
                    KFImage.url(viewModel.imageURL)
                        .placeholder {
                            Image(uiImage: .productPlaceholderImage)
                        }
                        .setProcessor(imageProcessor)
                        .resizable()
                        .scaledToFill()
                        .frame(width: Layout.productImageSize * scale, height: Layout.productImageSize * scale)
                        .cornerRadius(Layout.cornerRadius)
                        .foregroundColor(Color(UIColor.listSmallIcon))
                        .accessibilityHidden(true)

                    // Product details
                    VStack(alignment: .leading) {
                        Text(viewModel.name)
                            .bodyStyle()
                        Text(viewModel.productDetailsLabel)
                            .subheadlineStyle()
                        Text(viewModel.skuLabel)
                            .subheadlineStyle()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(viewModel.productAccessibilityLabel)
                .accessibilityHint(accessibilityHint)

                ProductStepper(viewModel: viewModel)
                    .renderedIf(viewModel.canChangeQuantity)
            }
        }
    }
}

/// Represents a custom stepper.
/// Used to change the quantity of the product in a `ProductRow`.
///
private struct ProductStepper: View {

    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: ProductRowViewModel

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        HStack {
            Button {
                viewModel.decrementQuantity()
            } label: {
                Image(uiImage: .minusSmallImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Layout.stepperButtonSize * scale)
            }
            .disabled(viewModel.shouldDisableQuantityDecrementer)

            Spacer()

            Text(viewModel.quantity.description)

            Spacer()

            Button {
                viewModel.incrementQuantity()
            } label: {
                Image(uiImage: .plusSmallImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Layout.stepperButtonSize * scale)
            }
        }
        .padding(Layout.stepperPadding * scale)
        .frame(width: Layout.stepperWidth * scale)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.stepperBorderRadius)
                .stroke(Color(UIColor.separator), lineWidth: Layout.stepperBorderWidth)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.name): \(Localization.quantityLabel)")
        .accessibilityValue(viewModel.quantity.description)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .decrement:
                viewModel.decrementQuantity()
            case .increment:
                viewModel.incrementQuantity()
            @unknown default:
                break
            }
        }
    }
}

private enum Layout {
    static let productImageSize: CGFloat = 48.0
    static let cornerRadius: CGFloat = 4.0
    static let stepperBorderWidth: CGFloat = 1.0
    static let stepperBorderRadius: CGFloat = 4.0
    static let stepperButtonSize: CGFloat = 22.0
    static let stepperPadding: CGFloat = 11.0
    static let stepperWidth: CGFloat = 112.0
    static let checkImageSize: CGFloat = 24.0
}

private enum Localization {
    static let quantityLabel = NSLocalizedString("Quantity", comment: "Accessibility label for product quantity field")
}

struct ProductRow_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProductRowViewModel(productOrVariationID: 1,
                                            name: "Love Ficus",
                                            sku: "123456",
                                            price: "20",
                                            stockStatusKey: "instock",
                                            stockQuantity: 7,
                                            manageStock: true,
                                            canChangeQuantity: true,
                                            imageURL: nil)
        let viewModelWithoutStepper = ProductRowViewModel(productOrVariationID: 1,
                                                          name: "Love Ficus",
                                                          sku: "123456",
                                                          price: "20",
                                                          stockStatusKey: "instock",
                                                          stockQuantity: 7,
                                                          manageStock: true,
                                                          canChangeQuantity: false,
                                                          imageURL: nil)

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
