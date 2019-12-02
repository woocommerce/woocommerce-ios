@testable import Storage
@testable import Yosemite

/// Mock implementation of the FileStorage protocol.
/// It reads and writes the data from and to an object in memory.
///
final class MockInMemoryStorage: FileStorage {
    private let loader = PListFileStorage()

    /// A boolean value to test if a write to disk is requested
    ///
    var dataWriteIsHit: Bool = false

    /// A boolean value to test if a file deletion is requested
    ///
    var deleteIsHit: Bool = false

    private var data: Data?

    func data(for fileURL: URL) throws -> Data {
        guard let data = data else {
            throw AppSettingsStoreErrors.deletePreselectedProvider
        }
        return data
    }

    func write(_ data: Data, to fileURL: URL) throws {
        self.data = data
    }

    func deleteFile(at fileURL: URL) throws {
        data = nil
        deleteIsHit = true
    }
}
