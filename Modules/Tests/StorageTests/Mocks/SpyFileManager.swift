import Foundation

import XCTest

@testable import Storage

/// Unlike `MockFileManager`, this performs the actual `FileManager` operations but can also
/// record or stub method calls if needed.
///
final class SpyFileManager {

    private let spiedFileManager: FileManager

    /// Moved items. The key is the source path. The value is the destination path.
    private(set) var movedItems = [String: String]()

    /// File paths of deleted items.
    private(set) var deletedItems = [String]()

    init(_ fileManager: FileManager = .default) {
        spiedFileManager = fileManager
    }
}

extension SpyFileManager: FileManagerProtocol {
    func fileExists(atPath path: String) -> Bool {
        spiedFileManager.fileExists(atPath: path)
    }

    func removeItem(at URL: URL) throws {
        try spiedFileManager.removeItem(at: URL)
        deletedItems.append(URL.path)
    }

    func removeItem(atPath path: String) throws {
        try spiedFileManager.removeItem(atPath: path)
        deletedItems.append(path)
    }

    func createDirectory(at url: URL,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws {
        try spiedFileManager.createDirectory(at: url,
                                             withIntermediateDirectories: createIntermediates,
                                             attributes: attributes)
    }

    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws {
        try spiedFileManager.createDirectory(atPath: path,
                                             withIntermediateDirectories: createIntermediates,
                                             attributes: attributes)
    }

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        try spiedFileManager.contentsOfDirectory(atPath: path)
    }

    func moveItem(atPath srcPath: String, toPath dstPath: String) throws {
        try spiedFileManager.moveItem(atPath: srcPath, toPath: dstPath)
        movedItems[srcPath] = dstPath
    }

    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        try spiedFileManager.moveItem(at: srcURL, to: dstURL)
        movedItems[srcURL.path] = dstURL.path
    }
}
