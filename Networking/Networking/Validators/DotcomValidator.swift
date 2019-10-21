import Foundation

/// WordPress.com Response Validator
///
enum DotcomValidator {

    /// Returns the DotcomError contained in a given Data Instance (if any).
    ///
    static func error(from response: Data) -> Error? {
        return try? JSONDecoder().decode(DotcomError.self, from: response)
    }
}
