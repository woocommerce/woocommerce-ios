import Foundation

extension NSDecimalNumber {

    /// Returns true if the receiver is equal to zero, false otherwise.
    ///
    func isZero() -> Bool {
        if NSDecimalNumber.zero.compare(self) == .orderedSame {
            return true
        }

        return false
    }
}
