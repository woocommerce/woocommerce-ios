import Foundation

/// Remote type to fetch the user's IP Location using a 3rd party API.
///
public final class IPLocationRemote: Remote {

    public func getIPCountryCode(onCompletion: @escaping (Result<String, Error>) -> Void) {

        guard let url = URL(string: "https://ipinfo.io/json") else {
            return // DO SOMETHING
        }

        let request = UnauthenticatedRequest(request: .init(url: url))
        let mapper = IPCountryCodeMapper()
        enqueue(request, mapper: mapper, completion: onCompletion)
    }
}

private struct IPCountryCodeMapper: Mapper {

    struct Response: Decodable {
        enum CodingKeys: String, CodingKey {
            case countryCode = "country"
        }

        let countryCode: String
    }

    func map(response: Data) throws -> String {
        try JSONDecoder().decode(Response.self, from: response).countryCode
    }
}
