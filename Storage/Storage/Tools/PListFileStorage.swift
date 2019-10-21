import Foundation

/// Implementation of the FileStorage protocol that reads and writes
/// from and to a plist file at a given URL
///
public final class PListFileStorage: FileStorage {
    public init() {}

    public func data(for fileURL: URL) throws -> Data {
        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            let error = PListFileStorageErrors.fileReadFailed
            throw error
        }
    }

    public func write(_ data: Data, to fileURL: URL) throws {
        do {
            try data.write(to: fileURL)
        } catch {
            let error = PListFileStorageErrors.fileWriteFailed
            throw error
        }
    }

    public func deleteFile(at fileURL: URL) throws {
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            let error = PListFileStorageErrors.fileDeleteFailed
            throw error
        }
    }
}

/// Errors
///
enum PListFileStorageErrors: Error {
    case fileReadFailed
    case fileWriteFailed
    case fileDeleteFailed
}
