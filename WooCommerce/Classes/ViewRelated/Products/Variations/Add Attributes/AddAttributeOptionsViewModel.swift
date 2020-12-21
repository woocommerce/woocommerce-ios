import Foundation
import Yosemite

/// Provides view data for Add Attributes, and handles init/UI/navigation actions needed.
///
final class AddAttributeOptionsViewModel {

    typealias Section = AddAttributeOptionsViewController.Section
    typealias Row = AddAttributeOptionsViewController.Row

    var titleView: String? {
        newAttributeName ?? attribute?.name
    }
    private(set) var newAttributeName: String?
    private(set) var attribute: ProductAttribute?

    private(set) var sections: [Section] = []

    init(newAttribute: String?) {
        self.newAttributeName = newAttribute
        updateSections()
    }

    init(existingAttribute: ProductAttribute) {
        self.attribute = existingAttribute
        updateSections()
    }

}

// MARK: - Synchronize Product Attribute terms
//
private extension AddAttributeOptionsViewModel {
    // TODO: to be implemented - fetch of terms

    /// Updates  data in sections
    ///
    func updateSections() {
        let textFieldSection = Section(header: nil, footer: Localization.footerTextField, rows: [.termTextField])
        let selectedTermsSection = Section(header: Localization.headerSelectedTerms, footer: nil, rows: [.selectedTerms])
        let existingTermsSection = Section(header: Localization.headerExistingTerms, footer: nil, rows: [.existingTerms])
        sections = [textFieldSection, selectedTermsSection, existingTermsSection].compactMap { $0 }
    }
}

private extension AddAttributeOptionsViewModel {
    enum Localization {
        static let footerTextField = NSLocalizedString("Add each option and press enter",
                                                       comment: "Footer of text field section in Add Attribute Options screen")
        static let headerSelectedTerms = NSLocalizedString("OPTIONS OFFERED",
                                                           comment: "Header of selected attribute options section in Add Attribute Options screen")
        static let headerExistingTerms = NSLocalizedString("ADD OPTIONS",
                                                           comment: "Header of existing attribute options section in Add Attribute Options screen")
    }
}
