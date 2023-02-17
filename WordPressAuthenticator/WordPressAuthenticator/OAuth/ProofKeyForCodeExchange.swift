// See:
// - https://developers.google.com/identity/protocols/oauth2/native-app#step1-code-verifier
// - https://www.rfc-editor.org/rfc/rfc7636
//
// FIXME: follow spec!
//
// A code_verifier is a high-entropy cryptographic random string using the unreserved
// characters [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~", with a minimum length of 43
// characters and a maximum length of 128 characters.
//
// The code verifier should have enough entropy to make it impractical to guess the value.
//
// Note: The common abbreviation of "Proof Key for Code Exchange" is PKCE and is pronounced "pixy".
struct ProofKeyForCodeExchange {

    enum Method {
        case s256
        case plain

        var urlQueryParameterValue: String {
            switch self {
            case .plain: return "plain"
            case .s256: return "S256"
            }
        }
    }

    let codeVerifier: CodeVerifier
    let method: Method

    init(codeVerifier: CodeVerifier = CodeVerifier(), method: Method = .s256) {
        self.codeVerifier = codeVerifier
        self.method = method
    }

    var codeCallenge: String {
        switch method {
        case .s256:
            // The spec defines code_challenge for the s256 mode as:
            //
            // code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))
            //
            // We don't need the ASCII conversion, because we build `CodeVerifier` from URL safe
            // characters.
            //
            // In the same way, it is safe to force unwrap the `Data` conversion because the
            // `CodeVerifier` input is guaranteed to have only UTF-8 representable characters.
            //
            // Also worth noting that `.data(using: .utf8)` cannot technically return `nil` anyway.
            // See https://forums.swift.org/t/can-encoding-string-to-data-with-utf8-fail/22437/4.
            let rawData = codeVerifier.rawValue.data(using: .utf8)!
            let hashedData: Data = rawData.sha256Hashed()
            return hashedData.base64URLEncodedString()
        case .plain:
            return codeVerifier.rawValue
        }
    }
}

extension ProofKeyForCodeExchange {

    struct CodeVerifier: Equatable {

        let rawValue: String

        private let allowedCharacters = Character.urlSafeCharacters
        static let minimumLength = 43
        static let maximumLength = 128

        /// `length` must be between 43 and 128, inclusive.
        init(length: Int = CodeVerifier.maximumLength) {
            let constrainedLength = min(max(length, CodeVerifier.minimumLength), CodeVerifier.maximumLength)
            rawValue = String.randomString(using: allowedCharacters, withLength: constrainedLength)
        }

        // This is a helper for the tests.
        //
        // Unfortunately, it needs to be part of the production code because Swift doesn't allow adding
        // non-convenience initializers outside the module.

        init?(value: String) {
            guard value.count >= CodeVerifier.minimumLength, value.count <= CodeVerifier.maximumLength else { return nil }

            guard Set(value).isSubset(of: allowedCharacters) else { return nil }

            self.rawValue = value
        }
    }
}
