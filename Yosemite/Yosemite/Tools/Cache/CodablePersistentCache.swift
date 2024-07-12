import Foundation

struct CodableCacheEntry<T: Codable>: Codable {
    let timestamp: Date
    let value: T
    let timeToLive: TimeInterval

    init(value: T, timeToLive: TimeInterval) {
        self.timestamp = .now
        self.value = value
        self.timeToLive = timeToLive
    }

    var isValid: Bool {
        return Date().timeIntervalSince(timestamp) < timeToLive
    }
}

// A class to handle persistent caching of Codable objects tied to a Site
class CodablePersistentCache<T: Codable> {
    private let cacheDirectory: URL
    private let fileManager: FileManager

    init() {
        self.fileManager = FileManager.default

        // Create a URL for the cache directory
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = urls[0]
            .appendingPathComponent(String(describing: T.self))

        // Create the cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func save(_ object: CodableCacheEntry<T>, forKey key: String) {
        debugPrint("Cache: saving data for \(key) in \(cacheDirectory)")
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            let data = try JSONEncoder().encode(object)
            debugPrint("caching data", data, fileURL)
            try data.write(to: fileURL)
        } catch {
            print("Cache: failed to save data: \(error)")
        }
    }

    func load(forKey key: String) throws -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        do {
            let decoder = JSONDecoder()
            let entry = try JSONDecoder().decode(CodableCacheEntry<T>.self, from: data)
            if entry.isValid {
                return entry.value
            } else {
                remove(forKey: key)

                return nil
            }
        } catch {
            print("Cache: failed to load data: \(error)")

            throw error
        }
    }

    public func remove(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? fileManager.removeItem(at: fileURL)
    }

    func clear() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }
}
