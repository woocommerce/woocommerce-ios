import Foundation
import Yosemite

final class EditAttributesViewModel {

    /// Main product dependency
    ///
    private var product: Product

    /// If true, a done button will appear that allows the merchant to generate a variation
    ///
    private let allowVariationCreation: Bool

    init(product: Product, allowVariationCreation: Bool) {
        self.product = product
        self.allowVariationCreation = allowVariationCreation
    }
}

// MARK: View Controller Outputs
extension EditAttributesViewModel {
    /// Defines done button visibility
    ///
    var showDoneButton: Bool {
        allowVariationCreation
    }
}

// MARK: View Controller inputs
extension EditAttributesViewModel {

    /// Updates the view model output properties based on the provided `product`.
    ///
    func updateProduct(_ product: Product) {
        self.product = product
    }
}
