import Foundation

// A class to handle persistent caching of Codable objects tied to a Site
class SiteCodablePersistentCache<T: Codable> {
    private let cacheDirectory: URL
    private let fileManager: FileManager
    private let siteID: Int64

    init(siteID: Int64, directoryName: String) {
        self.fileManager = FileManager.default
        self.siteID = siteID

        // Create a URL for the cache directory
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = urls[0]
            .appendingPathComponent(String(siteID))
            .appendingPathComponent(directoryName)

        // Create the cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func save(_ object: T, forKey key: String) {
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
        debugPrint("Cache: loading data for \(key) in \(cacheDirectory)")
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        debugPrint("cache: loading data", data)

        do {
            let decoder = JSONDecoder()
            decoder.userInfo = [.siteID: siteID]
            let object = try decoder.decode(T.self, from: data)
            debugPrint("object", object)

            return object
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
