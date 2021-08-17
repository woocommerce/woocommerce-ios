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

    /// The type of the custom package, set to `box` by default
    ///
    @Published var packageType: PackageType = .box

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
        self.packageType = .box
    }
}

extension ShippingLabelCustomPackageFormViewModel {
    enum PackageType: String, CaseIterable {
        case box
        case letter

        var localizedName: String {
            switch self {
            case .box:
                return Localization.packageTypeBox
            case .letter:
                return Localization.packageTypeLetter
            }
        }

        enum Localization {
            static let packageTypeBox = NSLocalizedString("Box", comment: "Box package type, used to create a custom package in the Shipping Label flow")
            static let packageTypeLetter = NSLocalizedString("Envelope",
                                                             comment: "Envelope package type, used to create a custom package in the Shipping Label flow")
        }
    }
}
