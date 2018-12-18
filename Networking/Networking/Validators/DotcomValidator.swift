import Foundation


/// WordPress.com Response Validator
///
struct DotcomValidator {

    /// Returns the DotcomError contained in a given Response, if any.
    ///
    static func error(from response: Data) -> Error? {
        return try? JSONDecoder().decode(DotcomError.self, from: response)
    }

    /// Returns the DotcomError contained in a given dictionary. If any!
    ///
    static func error(from json: Any) -> Error? {
        guard let dictionary = json as? [AnyHashable: Any] else {
            return nil
        }

        return DotcomError(dictionary: dictionary)
    }
}
