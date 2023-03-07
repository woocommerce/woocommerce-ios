import Foundation

/// Mapper: Jetpack Connection URL
///
struct JetpackConnectionURLMapper: Mapper {

    /// (Attempts) to convert the response into a URL.
    ///
    func map(response: Data) throws -> URL {
        guard let escapedString = String(data: response, encoding: .utf8) else {
            throw JetpackConnectionRemote.ConnectionError.malformedURL
        }
        // The API returns an escaped string with double quotes, so we need to clean it up.
        let urlString = escapedString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\\", with: "")
        return try urlString.asURL()
    }
}
