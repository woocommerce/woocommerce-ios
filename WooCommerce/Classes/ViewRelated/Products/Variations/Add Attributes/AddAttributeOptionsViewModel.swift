import Foundation
import Yosemite

/// Provides view data for Add Attributes, and handles init/UI/navigation actions needed.
///
final class AddAttributeOptionsViewModel {

    typealias Section = AddAttributeOptionsViewController.Section
    typealias Row = AddAttributeOptionsViewController.Row

    private(set) var newAttributeName: String?
    private(set) var attribute: ProductAttribute?

    private(set) var sections: [Section] = []

    init(newAttribute: String?) {
        self.newAttributeName = newAttribute
    }

    init(existingAttribute: ProductAttribute) {
        self.attribute = existingAttribute
    }

}

// MARK: - Synchronize Product Attribute terms
//
private extension AddAttributeOptionsViewModel {
    // TODO: to be implemented - fetch of terms

    /// Updates  data in sections
    ///
    func updateSections(attributes: [ProductAttribute]) {
        //TODO: to be implemented
    }
}
