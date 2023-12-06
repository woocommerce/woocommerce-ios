import SwiftUI

/// Represents a custom stepper.
/// Used to change the quantity of the product in a `ProductRow`.
///
struct ProductStepper: View {
    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: ProductStepperViewModel

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
            .disabled(viewModel.shouldDisableQuantityIncrementer)
        }
        .padding(Layout.stepperPadding * scale)
        .frame(width: Layout.stepperWidth * scale)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.stepperBorderRadius)
                .stroke(Color(UIColor.separator), lineWidth: Layout.stepperBorderWidth)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.accessibilityLabel)
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

struct ProductStepper_Previews: PreviewProvider {
    static var previews: some View {
        ProductStepper(viewModel: .init(quantity: 2, name: "Rooibos tea", minimumQuantity: 1, maximumQuantity: 5, quantityUpdatedCallback: { _ in }))
    }
}
