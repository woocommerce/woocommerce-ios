import Foundation

/// Manages the storage of task response data, persisting it in a cache.
/// Stores data for each task identifier in a separate file in the cache directory.
public final class MediaUploadSessionTaskStorage {
    // MARK: - Properties

    /// Directory where task data is stored
    private static let cacheDirectoryURL: URL = {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDirectory.appendingPathComponent("MediaUploadTaskData", isDirectory: true)
    }()

    /// Serial queue for thread-safe access
    private static let ioQueue = DispatchQueue(label: "com.automattic.MediaUploadSessionTaskStorage.ioQueue")

    // MARK: - Public Methods

    /// Appends data for a given task identifier
    public static func appendData(_ data: Data, forTaskIdentifier identifier: Int) {
        ioQueue.sync {
            createCacheDirectoryIfNeeded()

            let fileURL = fileURL(for: identifier)
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            } else {
                try? data.write(to: fileURL)
            }
        }
    }

    /// Gets all data for a given task identifier
    public static func getData(forTaskIdentifier identifier: Int) -> Data? {
        var data: Data?
        ioQueue.sync {
            let fileURL = fileURL(for: identifier)
            data = try? Data(contentsOf: fileURL)
        }
        return data
    }

    /// Removes data for a given task identifier
    public static func removeData(forTaskIdentifier identifier: Int) {
        ioQueue.sync {
            let fileURL = fileURL(for: identifier)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    /// Cleans up all stored data
    public static func cleanupAllData() {
        ioQueue.sync {
            try? FileManager.default.removeItem(at: cacheDirectoryURL)
            createCacheDirectoryIfNeeded()
        }
    }

    // MARK: - Private Methods

    private static func createCacheDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            try? fileManager.createDirectory(at: cacheDirectoryURL,
                                          withIntermediateDirectories: true,
                                          attributes: nil)
        }
    }

    private static func fileURL(for taskIdentifier: Int) -> URL {
        return cacheDirectoryURL.appendingPathComponent("task-\(taskIdentifier).dat")
    }
}
