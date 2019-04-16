import Foundation

public final class PListFileStorage: FileStorage {
    public init() { }

    public func data(for fileURL: URL) throws -> Data {
        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            let error = PListFileStorageErrors.fileLoadFailed
            throw error
        }
    }
}

/// Errors
///
enum PListFileStorageErrors: Error {
    case fileLoadFailed
}
