extension String {

    /// Encodes `self` using base 64 URL-safe encoding.
    ///
    /// See https://tools.ietf.org/html/rfc4648#section-5
    var base64URLEncoded: String {
        let data = self.data(using: .utf8)!
        let base64EncodedString = data.base64EncodedString()
        return base64EncodedString.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
    }
}
