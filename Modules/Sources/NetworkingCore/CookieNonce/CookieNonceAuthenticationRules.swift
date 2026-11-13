import Foundation

public enum CookieNonceAuthenticationFailure: Error, Equatable, Sendable {
    case basicAuthenticationRequired
    case invalidCredentials
    case loginFailed(message: String)
    case inaccessibleLoginPage
    case inaccessibleAdminPage
    case invalidResponse
    case unacceptableStatusCode(Int)
}

public enum CookieNonceAuthenticationResponseStage: Equatable, Sendable {
    case preflight
    case credentials
    case dashboard
    case nonce
}

/// Pure request and response rules shared by the URLSession and Alamofire adapters.
public enum CookieNonceAuthenticationRules {
    public static func failure(
        statusCode: Int,
        authenticateHeader: String?,
        locationHeader: String?,
        stage: CookieNonceAuthenticationResponseStage
    ) -> CookieNonceAuthenticationFailure? {
        if containsBasicAuthentication(statusCode: statusCode, authenticateHeader: authenticateHeader) {
            return .basicAuthenticationRequired
        }
        switch statusCode {
        case 200..<300:
            return nil
        case 300...303, 307, 308:
            switch stage {
            case .preflight, .credentials, .dashboard:
                return locationHeader?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? nil : .invalidResponse
            case .nonce:
                return .invalidResponse
            }
        case 404, 410:
            switch stage {
            case .preflight:
                return .inaccessibleLoginPage
            case .credentials:
                return .unacceptableStatusCode(statusCode)
            case .dashboard, .nonce:
                return .inaccessibleAdminPage
            }
        default:
            return .unacceptableStatusCode(statusCode)
        }
    }

    public static func isRedirect(statusCode: Int) -> Bool {
        (300...303).contains(statusCode) || (307...308).contains(statusCode)
    }

    public static func credentialBody(username: String, password: String, redirectTo: URL) -> Data? {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "log", value: username),
            URLQueryItem(name: "pwd", value: password),
            URLQueryItem(name: "rememberme", value: "true"),
            URLQueryItem(name: "redirect_to", value: redirectTo.absoluteString)
        ]
        let characterSet = CharacterSet(charactersIn: "+").inverted
        return components.percentEncodedQuery?
            .addingPercentEncoding(withAllowedCharacters: characterSet)?
            .data(using: .utf8)
    }

    public static func credentialFailure(
        in html: String,
        endpoints: CookieNonceAuthenticationEndpoints
    ) -> CookieNonceAuthenticationFailure {
        let errorMessage = endpoints.loginErrorMessage(in: html)
        if let errorMessage, errorMessage.localizedCaseInsensitiveContains("captcha") {
            return .loginFailed(message: errorMessage)
        }
        if html.contains("document.querySelector('form').classList.add('shake')") {
            return .invalidCredentials
        }
        if let errorMessage {
            return .loginFailed(message: errorMessage)
        }
        return .invalidResponse
    }

    public static func validatedNonce(from data: Data) -> String? {
        guard let nonce = String(data: data, encoding: .utf8), nonce.unicodeScalars.count >= 2,
              nonce.unicodeScalars.allSatisfy(\.isASCIILetterOrNumber) else {
            return nil
        }
        return nonce
    }

    static func containsBasicAuthentication(statusCode: Int, authenticateHeader: String?) -> Bool {
        guard statusCode == 401, let authenticateHeader else {
            return false
        }
        return authenticationSegments(in: authenticateHeader).contains { segment in
            let parts = segment.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard parts.first?.lowercased() == "basic" else {
                return false
            }
            // `Basic = value` continues the preceding challenge's parameters.
            return parts.count == 1 || parts[1].first != "="
        }
    }

    private static func authenticationSegments(in header: String) -> [Substring] {
        var segments = [Substring]()
        var start = header.startIndex
        var index = start
        var isInsideQuotes = false
        var isEscaping = false

        while index < header.endIndex {
            let character = header[index]
            if isEscaping {
                isEscaping = false
            } else if character == "\\", isInsideQuotes {
                isEscaping = true
            } else if character == "\"" {
                isInsideQuotes.toggle()
            } else if character == ",", isInsideQuotes == false {
                segments.append(header[start..<index].trimmingWhitespace)
                start = header.index(after: index)
            }
            index = header.index(after: index)
        }
        segments.append(header[start..<header.endIndex].trimmingWhitespace)
        return segments
    }
}

private extension Substring {
    var trimmingWhitespace: Substring {
        let start = firstIndex(where: { $0.isWhitespace == false }) ?? endIndex
        let end = lastIndex(where: { $0.isWhitespace == false }).map(index(after:)) ?? endIndex
        return self[start..<end]
    }
}

private extension Unicode.Scalar {
    var isASCIILetterOrNumber: Bool {
        (48...57).contains(value) || (65...90).contains(value) || (97...122).contains(value)
    }
}
