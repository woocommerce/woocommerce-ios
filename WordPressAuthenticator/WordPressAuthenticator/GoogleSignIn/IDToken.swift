/// See https://developers.google.com/identity/openid-connect/openid-connect#obtainuserinfo
public struct IDToken {

    let email: String

    // TODO: Validate token! – https://developers.google.com/identity/openid-connect/openid-connect#validatinganidtoken
    init?(jwt: JWToken) {
        guard let email = jwt.payload["email"] as? String else {
            return nil
        }

        self.email = email
    }
}
