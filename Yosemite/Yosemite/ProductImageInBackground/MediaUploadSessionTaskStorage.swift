import Foundation
import struct Networking.WordPressMedia
import struct Networking.WordPressMediaMapper

public enum MediaUploadError: Error {
    case noDataFound
    case parsingError(Error)
}

/// Manages the storage of task response data, persisting it in a cache.
/// Stores data for each task metadata in a separate file in the cache directory.
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

    /// Appends data for a given task metadata
    public static func appendData(_ data: Data, forTaskMetadata metadata: TaskMetadata) {
        ioQueue.sync {
            createCacheDirectoryIfNeeded()

            let fileURL = fileURL(for: metadata)
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            } else {
                try? data.write(to: fileURL)
            }
        }
    }

    /// Gets all data for a given task metadata
    public static func getData(forTaskMetadata metadata: TaskMetadata) -> Data? {
        var data: Data?
        ioQueue.sync {
            let fileURL = fileURL(for: metadata)
            data = try? Data(contentsOf: fileURL)
        }
        return data
    }

    /// Removes data for a given task metadata
    public static func removeData(forTaskMetadata metadata: TaskMetadata) {
        ioQueue.sync {
            let fileURL = fileURL(for: metadata)
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

    /// Gets all stored task metadata
    public static func getAllTaskMetadata() -> [TaskMetadata] {
        var metadata: [TaskMetadata] = []
        ioQueue.sync {
            createCacheDirectoryIfNeeded()
            let fileManager = FileManager.default
            guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectoryURL, includingPropertiesForKeys: nil) else {
                return
            }

            metadata = files.compactMap { url in
                guard url.lastPathComponent.starts(with: "task-") else {
                    return nil
                }
                let fileName = url.lastPathComponent
                    .replacingOccurrences(of: "task-", with: "")
                    .replacingOccurrences(of: ".dat", with: "")
                let components = fileName.split(separator: "-").map { String($0) }
                guard components.count == 3,
                      let siteID = Int64(components[1]),
                      let productID = Int64(components[2]) else {
                    return nil
                }
                return TaskMetadata(uploadID: components[0], siteID: siteID, productID: productID)
            }
        }
        return metadata
    }

    /// Gets all task metadata for a specific site and product
    public static func getTaskMetadata(forSiteID siteID: Int64, productID: Int64) -> [TaskMetadata] {
        return getAllTaskMetadata().filter { $0.siteID == siteID && $0.productID == productID }
    }

    /// Attempts to parse stored data into WordPressMedia
    public static func parseWordPressMedia(forTaskMetadata metadata: TaskMetadata) -> Result<WordPressMedia, MediaUploadError> {
        guard let data = getData(forTaskMetadata: metadata) else {
            return .failure(.noDataFound)
        }

        do {
            let media = try WordPressMediaMapper().map(response: data)
            return .success(media)
        } catch {
            return .failure(.parsingError(error))
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

    private static func fileURL(for metadata: TaskMetadata) -> URL {
        return cacheDirectoryURL.appendingPathComponent("task-\(metadata.uploadID)-\(metadata.siteID)-\(metadata.productID).dat")
    }
}

public struct TaskMetadata: Codable {
    let uploadID: String
    let siteID: Int64
    let productID: Int64

    var stringValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return UUID().uuidString
        }
        return string
    }

    static func from(string: String) -> TaskMetadata? {
        guard let data = string.data(using: .utf8),
              let metadata = try? JSONDecoder().decode(TaskMetadata.self, from: data) else {
            return nil
        }
        return metadata
    }
}
