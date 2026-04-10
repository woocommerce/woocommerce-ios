import Alamofire
import Foundation

/// Makes URLRequest conform to Request.
extension URLRequest: NetworkingCore.Request {
    public func responseDataValidator() -> ResponseDataValidator {
        PlaceholderDataValidator()
    }
}
