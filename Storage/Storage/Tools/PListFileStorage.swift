import Foundation

/// Implementation of the FileStorage protocol that reads and writes
/// from and to a plist file at a given URL
///
public final class PListFileStorage: FileStorage {
    public init() { }

    public func data<T: Decodable>(for fileURL: URL) throws -> T {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = PropertyListDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PListFileStorageErrors.fileReadFailed
        }
    }

    public func write<T: Encodable>(_ data: T, to fileURL: URL) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let encodedData = try encoder.encode(data)
            try encodedData.write(to: fileURL)
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
