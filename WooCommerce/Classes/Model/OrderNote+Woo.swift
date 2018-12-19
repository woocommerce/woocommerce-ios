import Foundation
import Yosemite


// MARK: - OrderNote Helper Methods
//
extension OrderNote {

    /// Returns `true` if this note was generated by the system, `false` otherwise.
    ///
    var isSystemNote: Bool {
        return author.lowercased() == Constants.systemAuthor
    }
}

// MARK: - Constants!
//
extension OrderNote {
    enum Constants {
        static let systemAuthor = "system"
    }
}
