import SwiftUI
import Yosemite

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

    /// Validated custom package
    ///
    private var validatedCustomPackage: ShippingLabelCustomPackage? {
        guard hasValidName,
              hasValidDimension(packageLength),
              hasValidDimension(packageWidth),
              hasValidDimension(packageHeight),
              let boxWeight = validatedWeight else {
            return nil
        }
        let isLetter = packageType == .letter
        let dimensions = "\(packageLength) x \(packageWidth) x \(packageHeight)"
        return ShippingLabelCustomPackage(isUserDefined: true,
                                          title: packageName,
                                          isLetter: isLetter,
                                          dimensions: dimensions,
                                          boxWeight: boxWeight,
                                          maxWeight: 0)
    }

    init(package: ShippingLabelCustomPackage? = nil,
         lengthUnit: String? = ServiceLocator.shippingSettingsService.dimensionUnit,
         weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit) {
        self.lengthUnit = lengthUnit ?? ""
        self.weightUnit = weightUnit ?? ""
        self.packageName = package?.title ?? ""
        self.packageType = (package?.isLetter ?? false) ? .letter : .box
        self.packageLength = package?.getLength().description ?? ""
        self.packageWidth = package?.getWidth().description ?? ""
        self.packageHeight = package?.getHeight().description ?? ""
        self.emptyPackageWeight = package?.boxWeight.description ?? ""
    }
}

// MARK: - Validation
extension ShippingLabelCustomPackageFormViewModel {
    var hasValidName: Bool {
        packageName.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
    }

    /// Validates that a text field contains a string with Double value greater than 0
    /// - Parameter dimension: Text field containing the string to validate
    ///
    func hasValidDimension(_ dimension: String) -> Bool {
        let numericDimension = Double(dimension) ?? 0
        return numericDimension > 0
    }

    var validatedWeight: Double? {
        guard let numericWeight = Double(emptyPackageWeight), numericWeight >= 0 else {
            return nil
        }
        return numericWeight
    }
}

// MARK: - Subtypes
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
