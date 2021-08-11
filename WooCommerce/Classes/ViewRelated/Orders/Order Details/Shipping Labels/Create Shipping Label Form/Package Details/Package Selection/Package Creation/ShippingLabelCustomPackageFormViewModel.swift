import SwiftUI

/// View model for `ShippingLabelCustomPackageForm`.
///
final class ShippingLabelCustomPackageFormViewModel: ObservableObject {
    /// The length unit used in the store (e.g. "in")
    ///
    let lengthUnit: String

    /// The weight unit used in the store (e.g. "oz")
    ///
    let weightUnit: String

    /// The name of the custom package
    ///
    @Published var packageName: String = ""

    /// The length of the custom package
    ///
    @Published var packageLength: String = "0"

    /// The width of the custom package
    ///
    @Published var packageWidth: String = "0"

    /// The height of the custom package
    ///
    @Published var packageHeight: String = "0"

    /// The weight of the custom package when empty
    ///
    @Published var emptyPackageWeight: String = "0"

    init() {
        self.lengthUnit = "in" // TODO-4743: Initialize this with the store's length unit
        self.weightUnit = "oz" // TODO-4743: Initialize this with the store's weight unit
    }
}
