import Foundation

extension URL {

    // TODO: This is incomplete
    static func googleSignInAuthURL(clientId: String) throws -> URL {
        let baseURL = "https://accounts.google.com/o/oauth2/v2/auth"

        let queryItems = [
            ("client_id", clientId),
            ("response_type", "code")
        ].map { URLQueryItem(name: $0.0, value: $0.1) }

        if #available(iOS 16.0, *) {
            return URL(string: baseURL)!.appending(queryItems: queryItems)
        } else {
            var components = URLComponents(string: baseURL)!
            components.queryItems = queryItems
            return try components.asURL()
        }
    }
}
