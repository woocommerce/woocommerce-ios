import Testing
@testable import PointOfSale

struct POSCapabilityTests {
    @Test func test_rawValues_match_backend_capability_identifiers() {
        // When / Then
        #expect(POSCapability.viewPOS.rawValue == "view_pos")
        #expect(POSCapability.viewPOSSettings.rawValue == "view_pos_settings")
        #expect(POSCapability.editPOSSettings.rawValue == "edit_pos_settings")
        #expect(POSCapability.refundShopOrders.rawValue == "refund_shop_orders")
        #expect(POSCapability.publishShopCoupons.rawValue == "publish_shop_coupons")
    }

    @Test func test_allCases_is_exactly_the_supported_capability_set() {
        // When / Then
        #expect(Set(POSCapability.allCases.map(\.rawValue)) == [
            "view_pos",
            "view_pos_settings",
            "edit_pos_settings",
            "refund_shop_orders",
            "publish_shop_coupons"
        ])
    }
}
