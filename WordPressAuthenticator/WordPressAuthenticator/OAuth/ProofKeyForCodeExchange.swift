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

    let codeVerifier: String
    let method: Method

    init(codeVerifier: String, method: Method) {
        self.codeVerifier = codeVerifier
        self.method = method
    }

    var codeCallenge: String {
        switch method {
        case .s256:
            // TODO: code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))
            fatalError()
        case .plain:
            return codeVerifier
        }
    }
}

extension ProofKeyForCodeExchange {

    struct CodeVerifier: Equatable {

        let value: String

        // From the docs: using the unreserved characters [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~"
//        let _ = CharacterSet.urlQueryAllowed
        private let allowedCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        private lazy var allowedCharactersCount = UInt32(allowedCharacters.count)

        /// `length` must be between 43 and 128, inclusive.
        init(length: Int = 128) {
            let constrainedLength = min(max(length, 43), 128)
            value = String.randomString(usingCharacters: allowedCharacters, withLenght: constrainedLength)
        }
    }
}
