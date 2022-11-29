import Foundation

extension URL {

    // TODO: This is incomplete
    static func googleSignInAuthURL(clientId: String) throws -> URL {
        let baseURL = "https://accounts.google.com/o/oauth2/v2/auth"

        let queryItems = [
            ("client_id", clientId),
            ("redirect_uri", redirectURI(from: clientId)),
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

    private static func redirectURI(from clientId: String) -> String {
        // Google's client id is in the form: 123-abc245def.apps.googleusercontent.com
        // The redirect URI uses the reverse-DNS notation.
        let reverseDNSClientId = clientId.split(separator: ".").reversed().joined(separator: ".")
        // After that, we add "oautha2callback", as per GIDSignIn.m line 421 at
        // commit 1b0c4ec33a6fe282f4fa35d8ac64263230ddaf36
        return "\(reverseDNSClientId):/oauth2callback"
    }
}
