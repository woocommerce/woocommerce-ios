/// Mapper: WCPayCharge
///
struct WCPayChargeMapper: Mapper {
    let siteID: Int64

    /// (Attempts) to convert a dictionary into an account.
    ///
    func map(response: Data) throws -> WCPayCharge {
        let decoder = JSONDecoder()
        decoder.userInfo = [.siteID: siteID]

        /// Needed for currentDeadline, which is given as a UNIX timestamp.
        /// Unfortunately other properties use other formats for dates, but we
        /// can cross that bridge when we need those decoded.
        decoder.dateDecodingStrategy = .secondsSince1970

        return try extract(
            from: response,
            using: decoder
        )
    }
}
