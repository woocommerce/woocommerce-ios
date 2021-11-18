import Foundation

/// Mapper: From WooCommerce site settings response to a boolean that indicates whether WooCommerce is active on the site
///
struct WooCommerceAvailabilityMapper: Mapper {

    /// Any store with valid WooCommerce site settings response data is considered to have an active WooCommerce plugin.
    ///
    func map(response: Data) throws -> Bool {
        true
    }
}
