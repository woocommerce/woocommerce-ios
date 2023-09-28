/// Mapper: WCPay account
///
struct WCPayAccountMapper: Mapper {

    /// (Attempts) to convert a dictionary into an account.
    ///
    func map(response: Data) throws -> WCPayAccount {
        let decoder = JSONDecoder()

        /// Needed for currentDeadline, which is given as a UNIX timestamp.
        /// Unfortunately other properties use other formats for dates, but we
        /// can cross that bridge when we need those decoded.
        decoder.dateDecodingStrategy = .secondsSince1970

        /// Prior to WooCommerce Payments plugin version 2.9.0 (Aug 2021) `data` could contain an empty array []
        /// indicating that the plugin was active but the merchant had not on-boarded (and therefore has no account.)
        if let _ = try? decoder.decode(Envelope<[String]>.self, from: response) {
            return WCPayAccount.noAccount
        } else if let _ = try? decoder.decode([String].self, from: response) {
            return WCPayAccount.noAccount
        }

        return try extract(from: response, using: decoder)
    }
}
