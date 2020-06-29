
import Foundation

import XCTest

@testable import Storage

/// A mock of `FileManager` via `FileManagerProtocol`.
///
final class MockFileManager {

    private typealias FilePath = String

    private var fileExistsResults = [FilePath: Bool]()

    /// Invocation count of all mocked methods.
    private(set) var allMethodsInvocationCount: Int = 0

    /// Invocation count of `fileExists(atPath)`.
    private(set) var fileExistsInvocationCount: Int = 0

    /// Set the return value if `fileExists(atPath:)` is called.
    func whenCheckingIfFileExists(atPath path: String, thenReturn result: Bool) {
        fileExistsResults[path] = result
    }
}

// MARK: - FileManagerProtocol Conformance

extension MockFileManager: FileManagerProtocol {

    func fileExists(atPath path: String) -> Bool {
        allMethodsInvocationCount += 1
        fileExistsInvocationCount += 1

        guard let result = fileExistsResults[path] else {
            XCTFail("There are no mocked return values for `fileExists` with path \(path).")
            return false
        }

        return result
    }

    func removeItem(at URL: URL) throws {
        allMethodsInvocationCount += 1
    }

    func removeItem(atPath path: String) throws {
        allMethodsInvocationCount += 1
    }

    func createDirectory(at url: URL,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws {
        allMethodsInvocationCount += 1
    }

    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws {
        allMethodsInvocationCount += 1
    }

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        allMethodsInvocationCount += 1
        XCTFail("There are no mocked return values for this method.")
        return []
    }

    func moveItem(atPath srcPath: String, toPath dstPath: String) throws {
        allMethodsInvocationCount += 1
    }
}
