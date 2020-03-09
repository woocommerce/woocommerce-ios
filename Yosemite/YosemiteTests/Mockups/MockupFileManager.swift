import Foundation

/// A subclass of `FileManager` where the file existence is based on a dictionary whose key is the file path.
///
final class MockupFileManager: FileManager {
    var dataByFilePath: [String: Data] = [:]

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
}
