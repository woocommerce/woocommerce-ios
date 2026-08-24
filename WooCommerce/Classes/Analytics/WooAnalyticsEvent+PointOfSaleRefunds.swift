import PointOfSale
import WooFoundation

/// POS refund events emitted from the app target rather than from the PointOfSale module.
///
/// They belong to the POS refund funnel, so they live in the `PointOfSale` namespace and are
/// registered in `TracksProvider`'s POS event list to carry the `pos_` prefix, like the events the
/// module itself emits.
extension WooAnalyticsEvent.PointOfSale {

    /// Reported when a preview probe finds the server-calculated refund route missing and the
    /// site falls back to local calculation. The store's WooCommerce version arrives with the
    /// event as the `cached_woo_core_version` property every event carries.
    static func refundServerFlowUnavailable() -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .pointOfSaleRefundServerFlowUnavailable, properties: [:])
    }
}
