import Foundation


/// WordPress.com Response Validator
///
struct DotcomValidator {

    /// Returns the DotcomError contained in a given Response, if any.
    ///
    static func error(from response: Data) -> Error? {
        return try? JSONDecoder().decode(DotcomError.self, from: response)
    }
}
