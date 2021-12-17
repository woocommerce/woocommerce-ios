import SwiftUI
import Kingfisher

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
                    KFImage.url(viewModel.imageURL)
                        .placeholder {
                            Image(uiImage: .productPlaceholderImage)
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: Layout.productImageSize * scale, height: Layout.productImageSize * scale)
                        .cornerRadius(Layout.cornerRadius)
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
                // TODO: Decrement the product quantity
            } label: {
                Image(uiImage: .minusSmallImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Layout.stepperButtonSize * scale)
            }

            Text("\(viewModel.quantity)")

            Button {
                // TODO: Increment the product quantity
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
                break // TODO: Decrement the product quantity
            case .increment:
                break // TODO: Increment the product quantity
            @unknown default:
                break
            }
        }
    }
}

private enum Layout {
    static let productImageSize: CGFloat = 44.0
    static let cornerRadius: CGFloat = 4.0
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
                                            canChangeQuantity: true,
                                            imageURL: nil)
        let viewModelWithoutStepper = ProductRowViewModel(id: 1,
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
    }
}
