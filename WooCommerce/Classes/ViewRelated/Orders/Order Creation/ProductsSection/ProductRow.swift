import SwiftUI

/// Represent a single product row in the Product section of a New Order
///
struct ProductRow: View {
    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: ProductRowViewModel

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        VStack {
            AdaptiveStack(horizontalAlignment: .leading) {
                HStack(alignment: .top) {
                    // Product image
                    // TODO: Display actual product image when available
                    Image(uiImage: .productPlaceholderImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: Layout.productImageSize * scale, height: Layout.productImageSize * scale)
                        .foregroundColor(Color(UIColor.listSmallIcon))
                        .accessibilityHidden(true)

                    // Product details
                    VStack(alignment: .leading) {
                        Text(viewModel.name)
                        Text(viewModel.stockAndPriceLabel)
                            .subheadlineStyle()
                        Text(viewModel.skuLabel)
                            .subheadlineStyle()
                    }
                    .accessibilityElement(children: .combine)
                }

                Spacer()

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
        HStack(spacing: Layout.stepperSpacing * scale) {
            Button {
                viewModel.decrementQuantity()
            } label: {
                Image(uiImage: .minusSmallImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Layout.stepperButtonSize * scale)
            }
            .disabled(viewModel.shouldDisableQuantityDecrementer)

            Text("\(viewModel.quantity)")

            Button {
                viewModel.incrementQuantity()
            } label: {
                Image(uiImage: .plusSmallImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Layout.stepperButtonSize * scale)
            }
        }
        .padding(Layout.stepperSpacing/2 * scale)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.stepperBorderRadius)
                .stroke(Color(UIColor.separator), lineWidth: Layout.stepperBorderWidth)
        )
        .accessibilityElement(children: .ignore)
        .accessibility(label: Text(Localization.quantityLabel))
        .accessibility(value: Text("\(viewModel.quantity)"))
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
    static let productImageSize: CGFloat = 44.0
    static let stepperBorderWidth: CGFloat = 1.0
    static let stepperBorderRadius: CGFloat = 4.0
    static let stepperButtonSize: CGFloat = 22.0
    static let stepperSpacing: CGFloat = 22.0
}

private enum Localization {
    static let quantityLabel = NSLocalizedString("Quantity", comment: "Accessibility label for product quantity field")
}

struct ProductRow_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProductRowViewModel(id: 1,
                                            name: "Love Ficus",
                                            sku: "123456",
                                            price: "20",
                                            stockStatusKey: "instock",
                                            stockQuantity: 7,
                                            manageStock: true,
                                            canChangeQuantity: true)
        let viewModelWithoutStepper = ProductRowViewModel(id: 1,
                                                          name: "Love Ficus",
                                                          sku: "123456",
                                                          price: "20",
                                                          stockStatusKey: "instock",
                                                          stockQuantity: 7,
                                                          manageStock: true,
                                                          canChangeQuantity: false)

        ProductRow(viewModel: viewModel)
            .previewDisplayName("ProductRow with stepper")
            .previewLayout(.sizeThatFits)

        ProductRow(viewModel: viewModelWithoutStepper)
            .previewDisplayName("ProductRow without stepper")
            .previewLayout(.sizeThatFits)
    }
}
