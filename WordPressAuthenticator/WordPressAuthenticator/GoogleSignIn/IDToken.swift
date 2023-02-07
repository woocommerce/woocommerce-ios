/// See https://developers.google.com/identity/openid-connect/openid-connect#obtainuserinfo
public struct IDToken {

    public let token: String
    public let email: String

    // TODO: Validate token! – https://developers.google.com/identity/openid-connect/openid-connect#validatinganidtoken
    init?(jwt: JWToken) {
        guard let email = jwt.payload["email"] as? String else {
            return nil
        }

        self.token = jwt.encodedValue
        self.email = email
    }
}
