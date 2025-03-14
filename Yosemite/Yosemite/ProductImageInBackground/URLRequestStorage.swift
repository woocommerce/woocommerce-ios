import Foundation

/// Storage class for caching URLRequests to disk
public class URLRequestStorage {

    private static let storageURL: URL = {
        let fileManager = FileManager.default

        // Use shared container for background access
        let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.automattic.woocommerce")!
        return containerURL.appendingPathComponent("cached_requests.json")
    }()

    private static var cachedRequests: [String: CachedRequest] = {
        return loadFromDisk()
    }()

    /// Save a URLRequest with an identifier
    public static func saveRequest(_ request: URLRequest, forKey key: String) {
        guard let _ = request.url else { return }

        let cachedRequest = CachedRequest(request: request)
        cachedRequests[key] = cachedRequest
        saveToDisk()
    }

    /// Get a URLRequest by its identifier
    public static func getRequest(forKey key: String) -> URLRequest? {
        return cachedRequests[key]?.toURLRequest()
    }

    /// Remove a URLRequest
    public static func removeRequest(forKey key: String) {
        cachedRequests.removeValue(forKey: key)
        saveToDisk()
    }

    /// Clear all cached requests
    public static func clearAll() {
        cachedRequests.removeAll()
        saveToDisk()
    }

    // Save all cached requests to disk
    private static func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cachedRequests)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Error saving cached requests: \(error)")
        }
    }

    // Load cached requests from disk
    private static func loadFromDisk() -> [String: CachedRequest] {
        do {
            if FileManager.default.fileExists(atPath: storageURL.path) {
                let data = try Data(contentsOf: storageURL)
                let decoder = JSONDecoder()
                return try decoder.decode([String: CachedRequest].self, from: data)
            }
        } catch {
            print("Error loading cached requests: \(error)")
        }
        return [:]
    }

    private struct CachedRequest: Codable {
        let url: URL
        let httpMethod: String
        let allHTTPHeaderFields: [String: String]?
        let httpBodyData: Data?

        init(request: URLRequest) {
            self.url = request.url!
            self.httpMethod = request.httpMethod ?? "GET"
            self.allHTTPHeaderFields = request.allHTTPHeaderFields
            self.httpBodyData = request.httpBody
        }

        func toURLRequest() -> URLRequest {
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            request.allHTTPHeaderFields = allHTTPHeaderFields
            request.httpBody = httpBodyData
            return request
        }
    }
}
