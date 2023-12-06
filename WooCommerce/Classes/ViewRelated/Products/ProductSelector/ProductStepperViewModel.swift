import Foundation

/// View model for `ProductStepper` view.
final class ProductStepperViewModel: ObservableObject {
    /// Quantity of product in the order
    ///
    @Published private(set) var quantity: Decimal

    let accessibilityLabel: String

    /// Minimum value of the product quantity
    ///
    private let minimumQuantity: Decimal

    /// Optional maximum value of the product quantity
    ///
    private let maximumQuantity: Decimal?

    /// Whether the quantity can be decremented.
    ///
    var shouldDisableQuantityDecrementer: Bool {
        if removeProductIntent != nil { // Allow decrementing below minimum quantity to remove product
            return quantity < minimumQuantity
        } else {
            return quantity <= minimumQuantity
        }
    }

    /// Whether the quantity can be incremented.
    ///
    var shouldDisableQuantityIncrementer: Bool {
        guard let maximumQuantity else {
            return false
        }
        return quantity >= maximumQuantity
    }

    /// Closure to run when the quantity is changed.
    ///
    var quantityUpdatedCallback: (Decimal) -> Void

    /// Closure to run when the quantity is decremented below the minimum quantity.
    ///
    var removeProductIntent: (() -> Void)?

    init(quantity: Decimal,
         name: String,
         minimumQuantity: Decimal,
         maximumQuantity: Decimal?,
         quantityUpdatedCallback: @escaping (Decimal) -> Void,
         removeProductIntent: (() -> Void)? = nil) {
        self.quantity = quantity
        self.accessibilityLabel = "\(name): \(Localization.quantityLabel)"
        self.minimumQuantity = minimumQuantity
        self.maximumQuantity = maximumQuantity
        self.quantityUpdatedCallback = quantityUpdatedCallback
        self.removeProductIntent = removeProductIntent
    }

    /// Increment the product quantity.
    ///
    func incrementQuantity() {
        if let maximumQuantity, quantity >= maximumQuantity {
            return
        }

        quantity += 1

        quantityUpdatedCallback(quantity)
    }

    /// Decrement the product quantity.
    ///
    func decrementQuantity() {
        guard quantity > minimumQuantity else {
            removeProductIntent?()
            return
        }
        quantity -= 1

        quantityUpdatedCallback(quantity)
    }
}

private enum Localization {
    static let quantityLabel = NSLocalizedString("Quantity", comment: "Accessibility label for product quantity field")
}
