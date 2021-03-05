import Foundation
import Yosemite

final class RenameAttributesViewModel {

    /// Original name of the product attribute
    ///
    private let originalAttributeName: String

    /// New name of the product attribute
    ///
    private var newAttributeName: String?

    init(attributeName: String) {
        self.originalAttributeName = attributeName
    }

}

// MARK: - Actions
extension RenameAttributesViewModel {

    /// Prevents the Done button from being enabled when the new attribute name is empty
    ///
    var shouldEnableDoneButton: Bool {
        newAttributeName != ""
    }

    /// Name of the attribute
    ///
    var attributeName: String {
        newAttributeName ?? originalAttributeName
    }

    /// Sets the new attribute name
    ///
    /// - Parameter name: New attribute name
    func handleAttributeNameChange(_ name: String?) {
        newAttributeName = name
    }

    func hasUnsavedChanges() -> Bool {
        return attributeName != originalAttributeName && newAttributeName != nil
    }
}
