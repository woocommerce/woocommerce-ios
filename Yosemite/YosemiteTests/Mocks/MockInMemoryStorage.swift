@testable import Storage
@testable import Yosemite

/// Mock implementation of the FileStorage protocol.
/// It reads and writes the data from and to an object in memory.
///
final class MockInMemoryStorage: FileStorage {
    /// A boolean value to test if a write to disk is requested
    ///
    var dataWriteIsHit: Bool = false

    /// A boolean value to test if a file deletion is requested
    ///
    var deleteIsHit: Bool = false

    private(set) var data: [URL: Codable] = [:]

    func data<T>(for fileURL: URL) throws -> T where T: Decodable {
        guard let data = data[fileURL] as? T else {
            throw Error.readFailed
        }
        return data
    }

    func write<T>(_ data: T, to fileURL: URL) throws where T: Encodable {
        self.data[fileURL] = data as? Codable
        dataWriteIsHit = true
    }

    func deleteFile(at fileURL: URL) throws {
        data.removeValue(forKey: fileURL)
        deleteIsHit = true
    }
}

extension MockInMemoryStorage {
    enum Error: Swift.Error {
        case readFailed
    }
}
