import Foundation

final class WooShippingAddPackageViewModel: ObservableObject {
    // Holds values for all dimension input fields.
    // Using a dictionary so we can easily add/remove new types
    // if needed just by adding new case in enum
    @Published var fieldValues: [WooShippingAddPackageDimensionType: String] = [:]

    // Field values are invalid if one of them is empty
    var areFieldValuesInvalid: Bool {
        for (_, value) in fieldValues {
            if value.isEmpty {
                return true
            }
        }
        return fieldValues.count != WooShippingAddPackageDimensionType.allCases.count
    }

    func clearFieldValues() {
        fieldValues.removeAll()
    }
}

enum WooShippingAddPackageDimensionType: CaseIterable {
    case length, width, height
    var name: String {
        switch self {
        case .length:
            return Localization.length
        case .width:
            return Localization.width
        case .height:
            return Localization.height
        }
    }
}

extension WooShippingAddPackageDimensionType {
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
    }
}
