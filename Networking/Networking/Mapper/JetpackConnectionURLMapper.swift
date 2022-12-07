import Foundation

/// Mapper: Jetpack Connection URL
///
struct JetpackConnectionURLMapper: Mapper {

    /// (Attempts) to convert the response into a URL.
    ///
    func map(response: Data) throws -> URL {
        let escapedString = String(data: response, encoding: .utf8)
        // The API returns an escaped string with double quotes, so we need to clean it up.
        let urlString = escapedString?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\\", with: "")
        guard let string = urlString,
                let url = URL(string: string) else {
            throw JetpackConnectionRemote.ConnectionError.malformedURL
        }
        return url
    }
}
