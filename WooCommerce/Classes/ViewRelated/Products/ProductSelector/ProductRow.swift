import SwiftUI
import Kingfisher

struct SimplifiedProductRow: View {

    @ObservedObject var viewModel: ProductRowViewModel

    init(viewModel: ProductRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(Localization.orderCountLabel)
            Spacer()
            ProductStepper(viewModel: viewModel)
                .renderedIf(viewModel.canChangeQuantity)
        }
    }
}

private extension SimplifiedProductRow {
    enum Localization {
        static let orderCountLabel = NSLocalizedString(
            "Order Count",
            comment: "Text in the product row card that indicates the product quantity in an order")
    }
}

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
        VStack {
            AdaptiveStack(horizontalAlignment: .leading) {
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
                        Text(viewModel.secondaryProductDetailsLabel)
                            .subheadlineStyle()
                            .renderedIf(viewModel.secondaryProductDetailsLabel.isNotEmpty)
                    }
                    .multilineTextAlignment(.leading)
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

    private var checkbox: some View {
        Image(uiImage: viewModel.selectedState.image)
            .frame(width: Layout.checkImageSize * scale, height: Layout.checkImageSize * scale)
            .foregroundColor(.init(UIColor.brand))
    }
}

/// Subtype: SelectedState
///
extension ProductRow {
    enum SelectedState {
        case notSelected
        case partiallySelected
        case selected

        var image: UIImage {
            switch self {
            case .notSelected:
                return .checkEmptyCircleImage
            case .selected:
                return .checkCircleImage.withRenderingMode(.alwaysTemplate)
            case .partiallySelected:
                return .checkPartialCircleImage.withRenderingMode(.alwaysTemplate)
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

    @State private var textFieldValue: Decimal

    @FocusState private var textFieldFocused: Bool

    init(viewModel: ProductRowViewModel) {
        self.viewModel = viewModel
        self._textFieldValue = State(initialValue: viewModel.quantity)
    }

    var body: some View {
        HStack {
            Button {
                textFieldFocused = false
                let newQuantity = textFieldValue - 1.0
                viewModel.changeQuantity(to: newQuantity)
                // If we edit the value and the focus in the same operation, the value change can be ignored.
                DispatchQueue.main.async {
                    textFieldValue = newQuantity
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
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: true, vertical: false)
            .focused($textFieldFocused)
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
                    Spacer()
                    Button {
                        textFieldFocused = false
                        viewModel.changeQuantity(to: textFieldValue)
                    } label: {
                        Text(Localization.keyboardDoneButton)
                            .bold()
                    }
                }
            }

            Button {
                textFieldFocused = false
                let newQuantity = textFieldValue + 1.0
                viewModel.changeQuantity(to: newQuantity)
                // If we edit the value and the focus in the same operation, the value change can be ignored.
                DispatchQueue.main.async {
                    textFieldValue = newQuantity
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
                                            imageURL: nil,
                                            hasParentProduct: false,
                                            isConfigurable: true)
        let viewModelWithoutStepper = ProductRowViewModel(productOrVariationID: 1,
                                                          name: "Love Ficus",
                                                          sku: "123456",
                                                          price: "20",
                                                          stockStatusKey: "instock",
                                                          stockQuantity: 7,
                                                          manageStock: true,
                                                          canChangeQuantity: false,
                                                          imageURL: nil,
                                                          hasParentProduct: true,
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
