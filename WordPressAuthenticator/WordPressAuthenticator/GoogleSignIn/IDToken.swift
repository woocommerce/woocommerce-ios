/// See https://developers.google.com/identity/openid-connect/openid-connect#obtainuserinfo
public struct IDToken {

    // TODO: Validate token! – https://developers.google.com/identity/openid-connect/openid-connect#validatinganidtoken
    public let encodedValue: String

    private let decodedValue: [String: Any]

    public let email: String?

    public init(jwt: String) {
        encodedValue = jwt
        decodedValue = decode(jwtToken: jwt)
        email = decodedValue["email"] as? String
    }
}

// Credits: https://stackoverflow.com/a/40915703/809944
private func decode(jwtToken jwt: String) -> [String: Any] {
    let segments = jwt.components(separatedBy: ".")
    return decodeJWTPart(segments[1]) ?? [:]
}

private func base64UrlDecode(_ value: String) -> Data? {
    var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 = base64 + padding
    }
    return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
}

private func decodeJWTPart(_ value: String) -> [String: Any]? {
    guard let bodyData = base64UrlDecode(value),
          let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
        return nil
    }

    return payload
}
