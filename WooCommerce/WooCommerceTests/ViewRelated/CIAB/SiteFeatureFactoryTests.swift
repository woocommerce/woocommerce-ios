import Testing
@testable import WooCommerce
import Yosemite

struct SiteFeatureFactoryTests {

    // MARK: - Dashboard Cards

    @Test func makeProviders_when_standard_site_then_stock_card_enabled() {
        // Given
        let site = Site.fake().copy(isGarden: false)

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(providers.dashboardCards.isStockCardEnabled)
    }

    @Test func makeProviders_when_standard_site_then_store_setup_card_enabled() {
        // Given
        let site = Site.fake().copy(isGarden: false)

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(providers.dashboardCards.isStoreSetupCardEnabled)
    }

    @Test func makeProviders_when_ciab_site_then_stock_card_disabled() {
        // Given
        let site = Site.fake().copy(isGarden: true, gardenName: "commerce")

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(!providers.dashboardCards.isStockCardEnabled)
    }

    @Test func makeProviders_when_ciab_site_then_store_setup_card_disabled() {
        // Given
        let site = Site.fake().copy(isGarden: true, gardenName: "commerce")

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(!providers.dashboardCards.isStoreSetupCardEnabled)
    }

    // MARK: - Order Status Editing

    @Test func makeProviders_when_standard_site_then_order_status_editing_enabled() {
        // Given
        let site = Site.fake().copy(isGarden: false)

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(providers.orderStatusEditing.isOrderStatusEditingEnabled)
    }

    @Test func makeProviders_when_ciab_site_then_order_status_editing_disabled() {
        // Given
        let site = Site.fake().copy(isGarden: true, gardenName: "commerce")

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(!providers.orderStatusEditing.isOrderStatusEditingEnabled)
    }

    // MARK: - Shipment Splitting

    @Test func makeProviders_when_standard_site_then_split_shipments_enabled() {
        // Given
        let site = Site.fake().copy(isGarden: false)

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(providers.shipmentSplitting.isSplitShipmentsEnabled)
    }

    @Test func makeProviders_when_ciab_site_then_split_shipments_disabled() {
        // Given
        let site = Site.fake().copy(isGarden: true, gardenName: "commerce")

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(!providers.shipmentSplitting.isSplitShipmentsEnabled)
    }

    // MARK: - Product Routing

    @Test func makeProviders_when_standard_site_then_booking_routes_to_native() {
        // Given
        let site = Site.fake().copy(isGarden: false)

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(providers.productRouting.navigationTarget(for: .booking) == .nativeDetail)
    }

    @Test func makeProviders_when_ciab_site_then_booking_routes_to_web() {
        // Given
        let site = Site.fake().copy(isGarden: true, gardenName: "commerce")

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(providers.productRouting.navigationTarget(for: .booking) == .webView)
    }

    @Test func makeProviders_when_ciab_site_then_simple_routes_to_native() {
        // Given
        let site = Site.fake().copy(isGarden: true, gardenName: "commerce")

        // When
        let providers = SiteFeatureFactory.makeProviders(for: site)

        // Then
        #expect(providers.productRouting.navigationTarget(for: .simple) == .nativeDetail)
    }

    // MARK: - Nil Site (defaults to standard)

    @Test func makeProviders_when_nil_site_then_uses_standard_defaults() {
        // Given / When
        let providers = SiteFeatureFactory.makeProviders(for: nil as Yosemite.Site?)

        // Then
        #expect(providers.dashboardCards.isStockCardEnabled)
        #expect(providers.orderStatusEditing.isOrderStatusEditingEnabled)
        #expect(providers.shipmentSplitting.isSplitShipmentsEnabled)
        #expect(providers.productRouting.navigationTarget(for: .booking) == .nativeDetail)
    }
}
