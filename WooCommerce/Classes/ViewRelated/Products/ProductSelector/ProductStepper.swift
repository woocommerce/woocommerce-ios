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

    @Binding private var textFieldValue: Decimal

    @FocusState private var textFieldFocused: Bool

    init(viewModel: ProductStepperViewModel) {
        self.viewModel = viewModel
        self._textFieldValue = Binding(get: {
            viewModel.enteredQuantity
        }, set: { newQuantity in
            viewModel.enteredQuantity = newQuantity
        })
    }

    var body: some View {
        HStack {
            Button {
                let newQuantity = textFieldValue - 1.0
                viewModel.changeQuantity(to: newQuantity)
                textFieldValue = newQuantity
                // If we edit the value and the focus in the same operation, the value change can be ignored.
                DispatchQueue.main.async {
                    textFieldFocused = false
                }
            } label: {
                Image(systemName: "minus.circle")
                    .font(.system(size: Layout.stepperButtonSize))
            }
            .accessibilityHidden(true)
            .disabled(viewModel.shouldDisableQuantityDecrementer)

            TextField("",
                      value: $textFieldValue,
                      format: .number)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: true, vertical: false)
            .focused($textFieldFocused)
            .onChange(of: textFieldFocused) { newValue in
                // We may have unsaved changes in the text field, if switching focus to another text field.
                if newValue == false {
                    viewModel.resetEnteredQuantity()
                }
            }
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Group {
                        Spacer()
                        Button {
                            viewModel.changeQuantity(to: textFieldValue)
                            textFieldFocused = false
                        } label: {
                            Text(Localization.keyboardDoneButton)
                                .bold()
                        }
                    }
                    .renderedIf(textFieldFocused)
                }
            }

            Button {
                let newQuantity = textFieldValue + 1.0
                viewModel.changeQuantity(to: newQuantity)
                textFieldValue = newQuantity
                // If we edit the value and the focus in the same operation, the value change can be ignored.
                DispatchQueue.main.async {
                    textFieldFocused = false
                }
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: Layout.stepperButtonSize))
            }
            .accessibilityHidden(true)
            .disabled(viewModel.shouldDisableQuantityIncrementer)
        }
    }
}

private enum Layout {
    static let productImageSize: CGFloat = 48.0
    static let cornerRadius: CGFloat = 4.0
    static let stepperButtonSize: CGFloat = 24.0
    static let stepperPadding: CGFloat = 11.0
    static let checkImageSize: CGFloat = 24.0
}

private enum Localization {
    static let quantityLabel = NSLocalizedString("Quantity", comment: "Accessibility label for product quantity field")
    static let keyboardDoneButton = NSLocalizedString(
        "orderForm.productRow.keyboard.toolbar.done.button.title",
        value: "Done",
        comment: "The title for a button to dismiss the keyboard on the order creation/editing screen")
}
