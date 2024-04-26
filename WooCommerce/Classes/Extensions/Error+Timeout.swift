import Foundation
import enum Alamofire.AFError

extension Error {
    /// Indicates if a given error is an URL timeout error.
    ///
    var isTimeoutError: Bool {
        switch self {
        case is AFError:
            (self.asAFError?.underlyingError as? NSError)?.code == NSURLErrorTimedOut
        default:
            (self as NSError).code == NSURLErrorTimedOut
        }
    }
}
