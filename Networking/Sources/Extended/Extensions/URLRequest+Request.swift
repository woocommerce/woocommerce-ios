import Foundation

/// Makes URLRequest conform to Request.
extension URLRequest: Request {
    func responseDataValidator() -> ResponseDataValidator {
        PlaceholderDataValidator()
    }
}
