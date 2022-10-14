import Foundation

public protocol UTMParametersProviding {
    var parameters: [UTMParameterKey: String?] { get }
    var utmQueryItems: [URLQueryItem] { get }
}

public enum UTMParameterKey: String {
    case medium
    case campaign
    case source
    case term
    case content

    var name: String {
        return "utm_\(rawValue)"
    }
}

public extension UTMParametersProviding {
    var utmQueryItems: [URLQueryItem] {
        parameters.compactMapValues { $0 }
            .map { (key: UTMParameterKey, value: String) in
            URLQueryItem(name: key.name, value: value)
        }
    }

    func urlWithUtmParams(string urlString: String) -> URL? {
        guard var components = URLComponents(string: urlString) else {
            return nil
        }
        var queryItems = components.queryItems ?? [URLQueryItem]()
        let newQueryItems = utmQueryItems

        // Remove any existing query items which we will set, to avoid duplicates
        queryItems = queryItems.filter { existingItem in
            return !newQueryItems.contains { newItem in
                newItem.name == existingItem.name
            }
        }

        queryItems.append(contentsOf: newQueryItems)

        components.queryItems = queryItems
        return components.url
    }
}
