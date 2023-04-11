import XCTest
@testable import Networking

extension MockNetwork {
    /// Returns the parameters ("\(key)=\(value)") for the WC API query in the first network request URL.
    var queryParameters: [String]? {
        queryParametersDictionary?.map { "\($0.key)=\($0.value)" }
    }

    /// Returns the parameters dictionary for the WC API query in the first network request URL.
    var queryParametersDictionary: [String: Any]? {
        guard let request = requestsForResponseData.first,
              let urlRequest = try? request.asURLRequest(),
              let url = urlRequest.url,
              requestsForResponseData.count == 1 else {
            return nil
        }
        guard let urlComponents = URLComponents(string: url.absoluteString) else {
            return nil
        }

        if let dotcomRequest = request as? DotcomRequest {
            return dotcomRequest.parameters
        }

        let parameters = urlComponents.queryItems

        guard let queryString = parameters?.first(where: { $0.name == "query" })?.value,
              let queryData = queryString.data(using: .utf8),
              let queryDictionary = try? JSONSerialization.jsonObject(with: queryData) as? [String: String] else {
            return nil
        }
        return queryDictionary
    }
}
