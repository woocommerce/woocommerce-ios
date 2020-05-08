
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

    /// Returns the value of `.failure()` if `self` is a failure.
    ///
    public var failure: Failure? {
        guard case let .failure(error) = self else {
            return nil
        }

        return error
    }
}
