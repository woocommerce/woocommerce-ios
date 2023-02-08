/// See https://developers.google.com/identity/openid-connect/openid-connect#obtainuserinfo
public struct IDToken {

    public let token: JSONWebToken
    public let email: String

    // TODO: Validate token! – https://developers.google.com/identity/openid-connect/openid-connect#validatinganidtoken
    init?(jwt: JSONWebToken) {
        guard let email = jwt.payload["email"] as? String else {
            return nil
        }

        self.token = jwt
        self.email = email
    }
}
