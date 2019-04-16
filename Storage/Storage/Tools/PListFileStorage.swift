import Foundation

public final class PListFileStorage: FileStorage {
    public init() { }

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
}

/// Errors
///
enum PListFileStorageErrors: Error {
    case fileReadFailed
    case fileWriteFailed
}
