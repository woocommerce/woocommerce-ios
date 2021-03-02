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

    var shouldEnableDoneButton: Bool {
        newAttributeName != ""
    }

    func handleAttributeNameChange(_ name: String?) {
        newAttributeName = name
    }

    func hasUnsavedChanges() -> Bool {
        return newAttributeName != attributeName
    }
}
