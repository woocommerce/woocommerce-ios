import SwiftUI

/// Represent a single product row in the Product section of a New Order
///
struct ProductRow: View {
    let canChangeQuantity: Bool

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
                        Text("Love Ficus") // Fake data - product name
                        Text("7 in stock • $20.00") // Fake data - stock / price
                            .subheadlineStyle()
                        Text("SKU: 123456") // Fake data - SKU
                            .subheadlineStyle()
                    }
                    .accessibilityElement(children: .combine)
                }

                Spacer()

                ProductStepper()
                    .renderedIf(canChangeQuantity)
            }

            Divider()
        }
    }
}

/// Represents a custom stepper.
/// Used to change the quantity of the product in a `ProductRow`.
///
private struct ProductStepper: View {

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

            Text("1") // Fake data - quantity

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
        .accessibility(value: Text("1")) // Fake static data - quantity
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
        ProductRow(canChangeQuantity: true)
            .previewDisplayName("ProductRow with stepper")
            .previewLayout(.sizeThatFits)

        ProductRow(canChangeQuantity: false)
            .previewDisplayName("ProductRow without stepper")
            .previewLayout(.sizeThatFits)
    }
}
