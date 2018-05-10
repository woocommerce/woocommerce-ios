import Foundation


/// File-Loading Tools: Only for Unit Testing purposes.
///
class Loader {

    /// Default JSON Extension
    ///
    static let jsonExtension = "json"


    /// Loads the specified filename.type Resource, and returns it's JSON Representation.
    ///
    static func jsonObject(for filename: String, extension: String = jsonExtension) -> Any? {
        guard let data = contentsOf(filename, extension: `extension`) else {
            return nil
        }

        do {
            return try JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .mutableLeaves])
        } catch {
            NSLog("Parsing Error: \(error)")
        }

        return nil
    }


    /// Loads the contents of the specified file (in the current bundle), and returns it's contents as `Data`.
    ///
    static func contentsOf(_ filename: String, extension: String = jsonExtension) -> Data? {
        guard let url = Bundle(for: self).url(forResource: filename, withExtension: `extension`) else {
            return nil
        }

        return try? Data(contentsOf: url)
    }
}
