
import Foundation

extension Result {
    /// Indicates whether `self` is a `.success`.
    ///
    public var isSuccess: Bool {
        guard case .success = self else {
            return false
        }
        return true
    }

    /// Indicates whether `self` is a `.failure`.
    ///
    public var isFailure: Bool {
        !isSuccess
    }
}
