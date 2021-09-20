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
    @Published var packageLength: String {
        didSet {
            let sanitized = sanitizeNumericInput(packageLength)
            if packageLength != sanitized {
                packageLength = sanitized
            }
        }
    }

    /// The width of the custom package
    ///
    @Published var packageWidth: String {
        didSet {
            let sanitized = sanitizeNumericInput(packageWidth)
            if packageWidth != sanitized {
                packageWidth = sanitized
            }
        }
    }

    /// The height of the custom package
    ///
    @Published var packageHeight: String {
        didSet {
            let sanitized = sanitizeNumericInput(packageHeight)
            if packageHeight != sanitized {
                packageHeight = sanitized
            }
        }
    }

    /// The weight of the custom package when empty
    ///
    @Published var emptyPackageWeight: String {
        didSet {
            let sanitized = sanitizeNumericInput(emptyPackageWeight)
            if emptyPackageWeight != sanitized {
                emptyPackageWeight = sanitized
            }
        }
    }

    /// Validated custom package
    ///
    var validatedCustomPackage: ShippingLabelCustomPackage? {
        guard isPackageValidated, let boxWeight = NumberFormatter.double(from: emptyPackageWeight) else {
            return nil
        }
        let isLetter = packageType == .letter
        let dimensions = "\(packageLength) x \(packageWidth) x \(packageHeight)".replacingOccurrences(of: ",", with: ".")
        return ShippingLabelCustomPackage(isUserDefined: true,
                                          title: packageName,
                                          isLetter: isLetter,
                                          dimensions: dimensions,
                                          boxWeight: boxWeight,
                                          maxWeight: 0)
    }

    // MARK: Validation Properties

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

// MARK: - Validation & Sanitization
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
            .map { [weak self] in
                self?.validatePackageName($0) ?? false
            }
            .assign(to: &$isNameValidated)

        $packageLength
            .dropFirst()
            .map { [weak self] in
                self?.validatePackageDimension($0) ?? false
            }
            .assign(to: &$isLengthValidated)

        $packageWidth
            .dropFirst()
            .map { [weak self] in
                self?.validatePackageDimension($0) ?? false
            }
            .assign(to: &$isWidthValidated)

        $packageHeight
            .dropFirst()
            .map { [weak self] in
                self?.validatePackageDimension($0) ?? false
            }
            .assign(to: &$isHeightValidated)

        $emptyPackageWeight
            .dropFirst()
            .map { [weak self] in
                self?.validatePackageWeight($0) ?? false
            }
            .assign(to: &$isWeightValidated)
    }

    /// Sanitize string input to return only valid Double values
    ///
    func sanitizeNumericInput(_ value: String) -> String {
        guard NumberFormatter.double(from: value) != nil else {
            return String(value.dropLast())
        }
        return value
    }

    private func validatePackageName(_ name: String) -> Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
    }

    private func validatePackageDimension(_ dimension: String) -> Bool {
        guard dimension.isNotEmpty, let numericValue = NumberFormatter.double(from: dimension) else {
            return false
        }
        return numericValue > 0
    }

    private func validatePackageWeight(_ weight: String) -> Bool {
        guard let numericValue = NumberFormatter.double(from: weight) else {
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
