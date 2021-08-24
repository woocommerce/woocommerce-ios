import SwiftUI
import Yosemite
import Combine

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
    var validatedCustomPackage: ShippingLabelCustomPackage? {
        guard isPackageValidated, let boxWeight = Double(emptyPackageWeight) else {
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

    // MARK: Validation Properties & Publishers

    @Published private(set) var isNameValidated = true
    @Published private(set) var isLengthValidated = true
    @Published private(set) var isWidthValidated = true
    @Published private(set) var isHeightValidated = true
    @Published private(set) var isWeightValidated = true
    private var isPackageValidated: Bool {
        isNameValidated && isLengthValidated && isWidthValidated && isHeightValidated && isWeightValidated
    }

    // MARK: Initialization

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

        configureFormValidation()
    }
}

// MARK: - Validation
extension ShippingLabelCustomPackageFormViewModel {

    /// Validate each field on demand.
    /// This ensures the package can be validated accurately even if one of the fields hasn't changed from its initial value.
    ///
    func validatePackage() {
        isNameValidated = validatePackageName(packageName)
        isLengthValidated = validatePackageDimension(packageLength)
        isWidthValidated = validatePackageDimension(packageWidth)
        isHeightValidated = validatePackageDimension(packageHeight)
        isWeightValidated = validatePackageWeight(emptyPackageWeight)
    }

    /// Configure form validation, ignoring the initial value of each form field
    ///
    private func configureFormValidation() {
        $packageName
            .dropFirst()
            .map { self.validatePackageName($0) }
            .assign(to: &$isNameValidated)

        $packageLength
            .dropFirst()
            .map { self.validatePackageDimension($0) }
            .assign(to: &$isLengthValidated)

        $packageWidth
            .dropFirst()
            .map { self.validatePackageDimension($0) }
            .assign(to: &$isWidthValidated)

        $packageHeight
            .dropFirst()
            .map { self.validatePackageDimension($0) }
            .assign(to: &$isHeightValidated)

        $emptyPackageWeight
            .dropFirst()
            .map { self.validatePackageWeight($0) }
            .assign(to: &$isWeightValidated)
    }

    private func validatePackageName(_ name: String) -> Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
    }

    private func validatePackageDimension(_ dimension: String) -> Bool {
        guard let numericValue = Double(dimension) else {
            return false
        }
        return numericValue > 0
    }

    private func validatePackageWeight(_ weight: String) -> Bool {
        guard let numericValue = Double(weight) else {
            return false
        }
        return numericValue >= 0
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
