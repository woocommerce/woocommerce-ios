import Foundation

extension URL {
    func appendingProductPreviewParameters() -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "preview", value: "true"))
        components.queryItems = queryItems
        return components.url
    }
}
