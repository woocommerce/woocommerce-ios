import Testing
@testable import PointOfSale

struct POSCapabilityTests {
    @Test func test_rawValues_match_backend_capability_identifiers() {
        // When / Then
        #expect(POSCapability.createCoupons.rawValue == "woocommerce_pos_create_coupons")
        #expect(POSCapability.issueRefunds.rawValue == "woocommerce_pos_issue_refunds")
        #expect(POSCapability.viewPOSSettings.rawValue == "woocommerce_pos_view_settings")
        #expect(POSCapability.editPOSSettings.rawValue == "woocommerce_pos_edit_settings")
        #expect(POSCapability.managePOSStaff.rawValue == "woocommerce_pos_manage_staff")
        #expect(POSCapability.exitPOS.rawValue == "woocommerce_pos_exit")
    }

    @Test func test_allCases_is_exactly_the_supported_capability_set() {
        // Only the capabilities the client enforces are modelled; the cashier-baseline caps the server
        // also reports (process_sales / view_orders / apply_coupons) are intentionally excluded.
        #expect(Set(POSCapability.allCases.map(\.rawValue)) == [
            "woocommerce_pos_create_coupons",
            "woocommerce_pos_issue_refunds",
            "woocommerce_pos_view_settings",
            "woocommerce_pos_edit_settings",
            "woocommerce_pos_manage_staff",
            "woocommerce_pos_exit"
        ])
    }
}
