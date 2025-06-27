import Foundation

/// Protocol abstracting entities that read and write to a file on disk.
/// It is meant to be used with lightweight files (i.e. configuration plist)
/// and reads and writes happen on the main thread.
///
/// Reads and writes are not expected to be thread safe.
///
public protocol FileStorage {
    /// Reads a file at a given URL and returns the expected type if possible
    ///
    func data<T: Decodable>(for fileURL: URL) throws -> T

    /// Writes data of a given type to a file at `fileURL`
    ///
    func write<T: Encodable>(_ data: T, to fileURL: URL) throws

    /// Deletes a file at `fileURL`
    func deleteFile(at fileURL: URL) throws
}
