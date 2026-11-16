import Testing
@testable import PointOfSale

struct POSCapabilityTests {
    @Test func test_allCases_match_the_guarding_table_identifiers() {
        // When / Then
        #expect(POSCapability.allCases.map(\.rawValue) == [
            "woocommerce_pos_process_sales",
            "woocommerce_pos_view_orders",
            "woocommerce_pos_apply_coupons",
            "woocommerce_pos_create_coupons",
            "woocommerce_pos_issue_refunds",
            "woocommerce_pos_exit",
            "woocommerce_pos_manage_store_settings"
        ])
    }
}
