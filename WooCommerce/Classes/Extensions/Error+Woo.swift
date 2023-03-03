import Foundation

extension Error {
    /// If a localized description is available, use it for the error alert.
    /// Otherwise, use the provided fallback string.
    func prepareErrorMessage(fallback: String) -> String {
        let description = (self as NSError).localizedDescription
        guard description.isNotEmpty else {
            return fallback
        }
        return description
    }
}
