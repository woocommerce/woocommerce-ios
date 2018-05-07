import Foundation

/// Loads + Parses a JSON-Encoded file.
///
class JSONLoader {

    /// Default JSON Extension
    ///
    static let defaultJsonExtension = "json"


    /// Loads + Parses as JSON the specified filename.type.
    ///
    static func load<T>(filename: String, type: String = JSONLoader.defaultJsonExtension) -> T? {
        guard let path = path(for: filename, ofType: type), let data = load(at: path) else {
            return nil
        }

        return parse(data: data) as? T
    }

    /// Returns the Path for the specified Filename.Type, in the current bundle.
    ///
    private static func path(for filename: String, ofType type: String) -> String? {
        return Bundle(for: self).path(forResource: filename, ofType: type)
    }

    /// Loads the file at the specified path.
    ///
    private static func load(at path: String) -> Data? {
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    /// Parses a given Data instance as JSON.
    ///
    private static func parse(data: Data) -> Any? {
        var output: Any?
        do {
            output = try JSONSerialization.jsonObject(with: data as Data, options: [.mutableContainers, .mutableLeaves])
        } catch {
            NSLog("Parsing Error: \(error)")
        }

        return output
    }
}
