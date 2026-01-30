import Foundation

public enum APIMocks {
    public static func loadMockData(filename: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: filename, withExtension: "json") else {
            throw FileNotFoundError(filename: filename)
        }
        return try Data(contentsOf: url)
    }
}

public struct FileNotFoundError: Error, LocalizedError {
    let filename: String

    public var errorDescription: String? {
        "Mock file '\(filename).json' not found in APIMocks bundle"
    }
}
