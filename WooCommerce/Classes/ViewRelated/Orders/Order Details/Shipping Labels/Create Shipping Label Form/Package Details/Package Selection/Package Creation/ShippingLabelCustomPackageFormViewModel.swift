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
    private var validatedCustomPackage: ShippingLabelCustomPackage? {
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

    var isNameValidated = true
    var isLengthValidated = true
    var isWidthValidated = true
    var isHeightValidated = true
    var isWeightValidated = true
    var isPackageValidated = false

    lazy var packageNameValidation: ValidationPublisher = {
        $packageName.hasContent()
    }()

    lazy var packageLengthValidation: ValidationPublisher = {
        $packageLength.greaterThan(0)
    }()

    lazy var packageWidthValidation: ValidationPublisher = {
        $packageWidth.greaterThan(0)
    }()

    lazy var packageHeightValidation: ValidationPublisher = {
        $packageHeight.greaterThan(0)
    }()

    lazy var packageWeightValidation: ValidationPublisher = {
        $emptyPackageWeight.greaterThanOrEqualTo(0)
    }()

    /// Combines validation for all package dimensions; used to validate the entire package
    ///
    lazy var packageDimensionsValidation: ValidationPublisher = {
        Publishers.CombineLatest3(
            packageLengthValidation,
            packageWeightValidation,
            packageHeightValidation
        ).map { validatedLength, validatedWeight, validatedHeight in
            return validatedLength && validatedWeight && validatedHeight
        }.eraseToAnyPublisher()
    }()

    /// Validates all fields for a custom package
    ///
    lazy var packageValidation: ValidationPublisher = {
        Publishers.CombineLatest3(packageNameValidation,
                                  packageDimensionsValidation,
                                  packageWeightValidation)
            .map { validatedName, validatedDimensions, validatedWeight in
                return validatedName && validatedDimensions && validatedWeight
            }
            .eraseToAnyPublisher()
    }()

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
