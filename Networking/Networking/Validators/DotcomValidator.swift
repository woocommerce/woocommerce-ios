import Foundation


/// WordPress.com Response Validator
///
struct DotcomValidator {

    /// Returns the DotcomError contained in a given Data Instance (if any).
    ///
    static func error(from response: Data) -> Error? {
        return try? JSONDecoder().decode(DotcomError.self, from: response)
    }

    /// Returns the DotcomError contained in a given JSON Object (if any).
    ///
    static func error(from jsonObject: Any) -> Error? {
        guard let dictionary = jsonObject as? [AnyHashable: Any] else {
            return nil
        }

        return DotcomError(dictionary: dictionary)
    }
}
