import UIKit
import Yosemite

/// Provides view data for Add Attributes, and handles init/UI/navigation actions needed.
///
final class AddAttributeViewModel {

    typealias Section = AddAttributeViewController.Section
    typealias Row = AddAttributeViewController.Row

    private let product: ProductFormDataModel

    private(set) var attributes: [ProductAttribute]

    init(attributes: [ProductAttribute]) {
        self.attributes = attributes
    }

    var sections: [Section] {
        var attributesRows = [Row]()
        for index in 0..<attributes.count {
            attributesRows.append(.existingAttribute)
        }
        let attributesSection = Section(header: Localization.headerAttributes, footer: nil, rows: attributesRows)

        return [Section(header: nil, footer: Localization.footerTextField, rows: [.attributeTextField]), attributesSection]
    }
}

private extension AddAttributeViewModel {
    enum Localization {
        static let footerTextField = NSLocalizedString("Variation type (ie Color, Size)", comment: "Footer of text field section in Add Attribute screen")
        static let headerAttributes = NSLocalizedString("Or tap to select existing attribute", comment: "Header of attributes section in Add Attribute screen")
    }
}
