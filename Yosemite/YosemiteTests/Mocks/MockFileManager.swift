import Foundation
import XCTest

/// A subclass of `FileManager` where the file existence is based on a dictionary whose key is the file path.
///
final class MockFileManager: FileManager {
    var dataByFilePath: [String: Data] = [:]

    /// The mocked results for the `attributesOfItem(atPath:)`.
    private var attributesOfItemResults = [String: [FileAttributeKey: Any]]()

    override func fileExists(atPath path: String) -> Bool {
        return dataByFilePath[path] != nil
    }

    override func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey: Any]? = nil) -> Bool {
        dataByFilePath[path] = data
        return true
    }

    override func removeItem(at URL: URL) throws {
        dataByFilePath.removeValue(forKey: URL.path)
    }

    override func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        guard let attributes = attributesOfItemResults[path] else {
            XCTFail("No mocked attributes for path \(path)")
            return [:]
        }

        return attributes
    }
}

// MARK: - Mocking

extension MockFileManager {
    /// Sets the return value when `attributesOfItem(atPath:)` is called.
    func whenRetrievingAttributesOfItem(atPath path: String, thenReturn: [FileAttributeKey: Any]) {
        attributesOfItemResults[path] = thenReturn
    }
}
