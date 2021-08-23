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
    @Published var packageName: String

    /// The type of the custom package, set to `box` by default
    ///
    @Published var packageType: PackageType

    /// The length of the custom package
    ///
    @Published var packageLength: String

    /// The width of the custom package
    ///
    @Published var packageWidth: String

    /// The height of the custom package
    ///
    @Published var packageHeight: String

    /// The weight of the custom package when empty
    ///
    @Published var emptyPackageWeight: String

    init(lengthUnit: String? = ServiceLocator.shippingSettingsService.dimensionUnit,
         weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit,
         packageName: String = "",
         packageType: PackageType = .box,
         packageLength: String = "",
         packageWidth: String = "",
         packageHeight: String = "",
         emptyPackageWeight: String = "") {
        self.lengthUnit = lengthUnit ?? ""
        self.weightUnit = weightUnit ?? ""
        self.packageName = packageName
        self.packageType = packageType
        self.packageLength = packageLength
        self.packageWidth = packageWidth
        self.packageHeight = packageHeight
        self.emptyPackageWeight = emptyPackageWeight
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
