import Foundation
import Yosemite

/// Maps WooCommerce Core order statuses to CIAB simplified statuses for display and filtering.
///
/// CIAB sites use a simplified set of order statuses:
/// - **Open**: groups `pending`, `processing`, `on-hold`, and `failed`
/// - **Completed**, **Cancelled**, **Refunded**: 1:1 mapping with Core statuses
///
/// This mapper centralizes the conversion so display, filtering, and API queries stay consistent.
struct CIABOrderStatusMapper {

    /// The core statuses that map to the CIAB "Open" group.
    static let openStatuses: Set<OrderStatusEnum> = [.pending, .processing, .onHold, .failed]

    /// The slug used for the synthetic "open" status in CIAB.
    static let openSlug = "open"

    // MARK: - Display Mapping

    /// Returns the display name for an order status on a CIAB site.
    ///
    /// Statuses in the "Open" group return a localized "Open" label.
    /// All other statuses return their standard localized name.
    static func displayName(for status: OrderStatusEnum) -> String {
        if openStatuses.contains(status) {
            return Localization.open
        }
        return status.localizedName
    }

    /// Returns the `OrderStatusEnum` to use for styling on a CIAB site.
    ///
    /// Statuses in the "Open" group return `.custom("open")` so that UI components
    /// can apply a single badge style. All other statuses pass through unchanged.
    static func displayStatus(for status: OrderStatusEnum) -> OrderStatusEnum {
        if openStatuses.contains(status) {
            return .custom(openSlug)
        }
        return status
    }

    // MARK: - Filter Mapping

    /// Maps an array of `OrderStatus` options from the API into CIAB-friendly filter options.
    ///
    /// Replaces individual "Open" group statuses with a single synthetic "Open" entry.
    /// Only adds the "Open" option once and preserves non-open statuses in their original order.
    static func mapFilterOptions(_ statuses: [OrderStatus]) -> [OrderStatus] {
        var result: [OrderStatus] = []
        var openAdded = false

        for status in statuses {
            if openStatuses.contains(status.status) {
                if !openAdded {
                    // Insert a synthetic "Open" entry using the first open status's siteID and a total of 0.
                    let openStatus = OrderStatus(name: Localization.open,
                                                 siteID: status.siteID,
                                                 slug: openSlug,
                                                 total: 0)
                    result.append(openStatus)
                    openAdded = true
                }
                // Skip individual open statuses.
            } else {
                result.append(status)
            }
        }
        return result
    }

    /// Expands CIAB filter selections back to core statuses for API requests.
    ///
    /// When the user selects "Open" in the filter UI, this resolves it to the 4 underlying
    /// core statuses so the API returns the correct results.
    static func resolveFilterStatuses(_ statuses: [OrderStatusEnum]) -> [OrderStatusEnum] {
        var resolved: [OrderStatusEnum] = []
        for status in statuses {
            if status == .custom(openSlug) {
                resolved.append(contentsOf: openStatuses)
            } else {
                resolved.append(status)
            }
        }
        return resolved
    }
}

// MARK: - Localization

private extension CIABOrderStatusMapper {
    enum Localization {
        static let open = NSLocalizedString(
            "ciabOrderStatusMapper.open",
            value: "Open",
            comment: "Display label for the CIAB 'Open' order status, which groups pending, processing, on-hold, and failed orders."
        )
    }
}
