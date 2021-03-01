import Foundation
import Yosemite

final class RenameAttributesViewModel {

    let attributeName: String

    private(set) var newAttributeName: String?

    init(attributeName: String) {
        self.attributeName = attributeName
    }

}

// MARK: - Actions
extension RenameAttributesViewModel {

    func handleAttributeNameChange(_ name: String?) {
        guard name != nil && name?.isNotEmpty == true else {
            newAttributeName = nil
            return
        }

        newAttributeName = name
    }

    func hasUnsavedChanges() -> Bool {
        return newAttributeName != attributeName
    }
}
