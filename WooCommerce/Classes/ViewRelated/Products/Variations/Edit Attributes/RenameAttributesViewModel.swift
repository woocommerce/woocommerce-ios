import Foundation
import Yosemite

final class RenameAttributesViewModel {

    /// Current name of the product attribute
    ///
    let attributeName: String

    /// New name of the product attribute
    ///
    private(set) var newAttributeName: String?

    init(attributeName: String) {
        self.attributeName = attributeName
    }

}

// MARK: - Actions
extension RenameAttributesViewModel {

    /// Prevents the Done button from being enabled when the new attribute name is empty
    ///
    var shouldEnableDoneButton: Bool {
        newAttributeName != ""
    }

    /// Sets the new attribute name
    ///
    /// - Parameter name: New attribute name
    func handleAttributeNameChange(_ name: String?) {
        newAttributeName = name
    }

    func hasUnsavedChanges() -> Bool {
        return newAttributeName != attributeName && newAttributeName != nil
    }
}
