import Foundation

/// View model for `ProductStepper` view.
final class ProductStepperViewModel: ObservableObject {
    /// Quantity of product in the order
    ///
    @Published private(set) var quantity: Decimal

    /// Quantity as shown in the text field. This may be uncommitted, in which case it could differ from `quantity`
    ///
    @Published var enteredQuantity: Decimal

    /// When a decrement action would remove the product, we can use this property to emphasise that to the user
    ///
    @Published var decrementWillRemoveProduct: Bool = false

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
    let removeProductIntent: (() -> Void)?

    init(quantity: Decimal,
         name: String,
         minimumQuantity: Decimal = 1,
         maximumQuantity: Decimal? = nil,
         quantityUpdatedCallback: @escaping (Decimal) -> Void,
         removeProductIntent: (() -> Void)? = nil) {
        self.quantity = quantity
        self.accessibilityLabel = "\(name): \(Localization.quantityLabel)"
        self.minimumQuantity = minimumQuantity
        self.maximumQuantity = maximumQuantity
        self.quantityUpdatedCallback = quantityUpdatedCallback
        self.removeProductIntent = removeProductIntent
        self.enteredQuantity = quantity
        bindDecrementWillRemoveProduct()
    }

    private func bindDecrementWillRemoveProduct() {
        $enteredQuantity
            .map { [weak self] enteredQuantity in
                guard let self,
                    self.removeProductIntent != nil else {
                    return false
                }
                return enteredQuantity <= self.minimumQuantity
            }
            .assign(to: &$decrementWillRemoveProduct)
    }

    func resetEnteredQuantity() {
        enteredQuantity = quantity
    }

    func changeQuantity(to newQuantity: Decimal) {
        guard newQuantity != quantity else {
            // This stops unnecessary order edit submissions when editing starts via the text field
            return
        }

        guard newQuantity >= minimumQuantity else {
            removeProductIntent?()
            return
        }

        if let maximumQuantity,
            newQuantity > maximumQuantity {
            return
        }

        quantity = newQuantity
        quantityUpdatedCallback(newQuantity)
    }

    /// Increment the product quantity.
    ///
    func incrementQuantity() {
        changeQuantity(to: quantity + 1)
    }

    /// Decrement the product quantity.
    ///
    func decrementQuantity() {
        changeQuantity(to: quantity - 1)
    }
}

private enum Localization {
    static let quantityLabel = NSLocalizedString("Quantity", comment: "Accessibility label for product quantity field")
}