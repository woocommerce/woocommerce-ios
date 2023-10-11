import Foundation

/// Authentication token for WPCOM AI endpoint
///
struct JWToken {
    /// JWT
    ///
    let token: String

    /// Expiry date
    ///
    let expiryDate: Date

    /// Site ID
    ///
    let siteID: Int64
}
