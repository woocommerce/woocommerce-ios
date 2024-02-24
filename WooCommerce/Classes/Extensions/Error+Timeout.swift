import Foundation

extension Error {
    /// Indicates if a given error is an URL timeout error.
    ///
    var isTimeoutError: Bool {
        (self as NSError).code == NSURLErrorTimedOut
    }
}
