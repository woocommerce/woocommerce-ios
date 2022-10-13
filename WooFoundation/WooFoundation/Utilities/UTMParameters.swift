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
        queryItems.append(contentsOf: utmQueryItems)
        components.queryItems = queryItems
        return components.url
    }
}

public struct WooCommerceComUTMParametersProvider: UTMParametersProviding {
    public let parameters: [UTMParameterKey: String?]

    public init(campaign: String,
         source: String,
         content: String?) {
        parameters = [
            .medium: Constants.wooCommerceComUtmMedium,
            .campaign: campaign,
            .source: source,
            .content: content
        ]
    }

    private enum Constants {
        static let wooCommerceComUtmMedium = "woo_ios"
    }
}
