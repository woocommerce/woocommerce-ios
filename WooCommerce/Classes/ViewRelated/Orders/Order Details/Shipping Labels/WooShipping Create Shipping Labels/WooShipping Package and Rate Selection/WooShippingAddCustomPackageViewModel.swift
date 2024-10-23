import Foundation

final class WooShippingAddCustomPackageViewModel: ObservableObject {
    // Holds values for all dimension input fields.
    // Using a dictionary so we can easily add/remove new types
    // if needed just by adding new case in enum
    @Published var fieldValues: [WooShippingPackageUnitType: String] = [:]
    // Holds selected package type when custom package is selected, it can be `box` or `envelope`
    @Published var packageType: WooShippingPackageType = .box
    // Holds value for toggle that determines if we are showing button for saving the template
    @Published var showSaveTemplate: Bool = false
    @Published var packageTemplateName: String = ""
    // The dimension unit used in the store (e.g. "in")
    let dimensionUnit: String
    // The weight unit used in the store (e.g. "kg")
    let weightUnit: String

    // MARK: Initialization

    init(dimensionUnit: String? = ServiceLocator.shippingSettingsService.dimensionUnit,
         weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit) {
        self.dimensionUnit = dimensionUnit ?? ""
        self.weightUnit = weightUnit ?? ""
    }

    // Field values are invalid if one of them is empty
    // - if we are saving template we check all field values
    // - if we are not saving template we check only dimensions
    var areFieldValuesInvalid: Bool {
        let keysToCheck: [WooShippingPackageUnitType] = showSaveTemplate ? WooShippingPackageUnitType.allCases : WooShippingPackageUnitType.dimensionUnits

        var validFieldsCount: Int = 0

        for (key, value) in fieldValues {
            guard keysToCheck.contains(key) else { continue }
            if value.isEmpty {
                return true
            }
            validFieldsCount += 1
        }
        return validFieldsCount != keysToCheck.count
    }

    func clearFieldValues() {
        fieldValues.removeAll()
    }

    func resetValues() {
        clearFieldValues()
        packageType = .box
        showSaveTemplate = false
        packageTemplateName = ""
    }

    func addPackageAction() {
        // TODO: implement adding a package
        guard validateCustomPackageInputFields() else { return }

        // Cleanup after adding package
        resetValues()
    }

    func savePackageAsTemplateAction() {
        // TODO: implement saving package as a template
        guard validateCustomPackageInputFields() else { return }

        // Cleanup after saving package template
        resetValues()
    }

    func validateCustomPackageInputFields() -> Bool {
        guard !areFieldValuesInvalid else {
            return false
        }
        if showSaveTemplate {
            return !packageTemplateName.isEmpty
        }
        return true
    }
}

enum WooShippingPackageUnitType: CaseIterable {
    case length, width, height
    case weight
    var name: String {
        switch self {
        case .length:
            return Localization.length
        case .width:
            return Localization.width
        case .height:
            return Localization.height
        case .weight:
            return Localization.packageWeight
        }
    }

    static var dimensionUnits: [WooShippingPackageUnitType] {
        return [.length, .width, .height]
    }
}

extension WooShippingPackageUnitType {
    enum Localization {
        static let length = NSLocalizedString("wooShipping.createLabel.addPackage.length",
                                              value: "Length",
                                              comment: "Info label for length input field")
        static let width = NSLocalizedString("wooShipping.createLabel.addPackage.width",
                                             value: "Width",
                                             comment: "Info label for width input field")
        static let height = NSLocalizedString("wooShipping.createLabel.addPackage.height",
                                              value: "Height",
                                              comment: "Info label for height input field")
        static let packageWeight = NSLocalizedString("wooShipping.createLabel.addPackage.packageWeight",
                                              value: "Package Weight",
                                              comment: "Info label for weight input field")
    }
}

enum WooShippingPackageType: CaseIterable {
    case box, envelope
    var name: String {
        switch self {
        case .box:
            return Localization.box
        case .envelope:
            return Localization.envelope
        }
    }
}

extension WooShippingPackageType {
    enum Localization {
        static let box = NSLocalizedString("wooShipping.createLabel.addPackage.box",
                                           value: "Box",
                                           comment: "Info label for selected box as a package type")
        static let envelope = NSLocalizedString("wooShipping.createLabel.addPackage.envelope",
                                                value: "Envelope",
                                                comment: "Info label for selected envelope as a package type")
    }
}
