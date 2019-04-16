import Foundation

/// Protocol abstracting entities that read and write to a file on disk.
/// It is meant to be used with lightweight files (i.e. configuration plist)
/// and reads and writes happen on the main thread.
///
/// Reads and writes are not expected to be thread safe.
///
public protocol FileStorage {
    /// Reads a file at a given URL and returns is representation as `Data`
    ///
    func data(for fileURL: URL) throws -> Data

    /// Reads a `Data` blob to a file at `fileURL`
    ///
    func write(_ data: Data, to fileURL: URL) throws
}
