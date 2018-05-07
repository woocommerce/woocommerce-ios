import Foundation

/// Loads + Parses a JSON-Encoded file.
///
class JSONLoader {

    /// Loads + Parses as JSON the specified filename.type.
    ///
    func load<T>(filename: String, type: String) -> T? {
        guard let path = path(for: filename, ofType: type), let data = load(at: path) else {
            return nil
        }

        return parse(data: data) as? T
    }

    /// Returns the Path for the specified Filename.Type, in the current bundle.
    ///
    private func path(for filename: String, ofType type: String) -> String? {
        return Bundle(for: Swift.type(of: self)).path(forResource: filename, ofType: type)
    }

    /// Loads the file at the specified path.
    ///
    private func load(at path: String) -> Data? {
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    /// Parses a given Data instance as JSON.
    ///
    private func parse(data: Data) -> Any? {
        var output: Any?
        do {
            output = try JSONSerialization.jsonObject(with: data as Data, options: [.mutableContainers, .mutableLeaves])
        } catch {
            NSLog("Parsing Error: \(error)")
        }

        return output
    }
}
