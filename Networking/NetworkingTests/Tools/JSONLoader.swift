import Foundation


/// Loads + Parses a JSON-Encoded file.
///
class JSONLoader {

    /// Default JSON Extension
    ///
    static let defaultJsonExtension = "json"


    /// Loads the specified filename.type Resource, and returns it's JSON Representation.
    ///
    static func load<T>(filename: String, ofType type: String = JSONLoader.defaultJsonExtension) -> T? {
        guard let url = Bundle(for: self).url(forResource: filename, withExtension: type) else {
            return nil
        }

        do {
            return try JSONSerialization.jsonObject(with: Data(contentsOf: url), options: [.mutableContainers, .mutableLeaves]) as? T
        } catch {
            NSLog("Parsing Error: \(error)")
        }

        return nil
    }
}
