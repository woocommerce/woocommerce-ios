import Foundation

extension NSDecimalNumber {
    func isZero() -> Bool {
        let zeroValue = NSDecimalNumber.zero

        if zeroValue.compare(self) == .orderedSame {
            return true
        }

        return false
    }
}
