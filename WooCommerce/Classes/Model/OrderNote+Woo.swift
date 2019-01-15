import Foundation
import Yosemite


// MARK: - OrderNote Helper Methods
//
extension OrderNote {

    /// Returns `true` if this note's author is the system, `false` otherwise.
    ///
    var isSystemAuthor: Bool {
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
