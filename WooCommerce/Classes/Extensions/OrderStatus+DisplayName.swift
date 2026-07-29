import Yosemite

extension Collection where Element == OrderStatus {
    /// Returns the server-provided display name for the given status (follows the store's
    /// wp-admin language), falling back to the app's localized name when no match is found.
    func displayName(for status: OrderStatusEnum) -> String {
        let slug = status.rawValue
        return first { $0.slug == slug }?.name ?? status.localizedName
    }
}
