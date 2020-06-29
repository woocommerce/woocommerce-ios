
import Foundation

import XCTest

@testable import Storage

/// A mock of `FileManager` via `FileManagerProtocol`.
///
final class MockFileManager {

}

// MARK: - FileManagerProtocol Conformance

extension MockFileManager: FileManagerProtocol {

    func fileExists(atPath path: String) -> Bool {
        XCTFail("There are no mocked return values for this method.")
        return false
    }

    func removeItem(at URL: URL) throws {

    }

    func removeItem(atPath path: String) throws {

    }

    func createDirectory(at url: URL,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws {

    }

    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws {

    }

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        XCTFail("There are no mocked return values for this method.")
        return []
    }

    func moveItem(atPath srcPath: String, toPath dstPath: String) throws {

    }
}
