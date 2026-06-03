import Testing
@testable import PointOfSale

struct POSCapabilityTests {
    @Test func test_rawValues_match_backend_capability_identifiers() {
        // When / Then
        #expect(POSCapability.processSales.rawValue == "pos_process_sales")
        #expect(POSCapability.viewOrders.rawValue == "pos_view_orders")
        #expect(POSCapability.applyCoupons.rawValue == "pos_apply_coupons")
        #expect(POSCapability.createCoupons.rawValue == "pos_create_coupons")
        #expect(POSCapability.issueRefunds.rawValue == "pos_issue_refunds")
        #expect(POSCapability.viewPOSSettings.rawValue == "pos_view_settings")
        #expect(POSCapability.editPOSSettings.rawValue == "pos_edit_settings")
        #expect(POSCapability.managePOSStaff.rawValue == "pos_manage_staff")
        #expect(POSCapability.exitPOS.rawValue == "pos_exit")
    }

    @Test func test_allCases_is_exactly_the_supported_capability_set() {
        // When / Then
        #expect(Set(POSCapability.allCases.map(\.rawValue)) == [
            "pos_process_sales",
            "pos_view_orders",
            "pos_apply_coupons",
            "pos_create_coupons",
            "pos_issue_refunds",
            "pos_view_settings",
            "pos_edit_settings",
            "pos_manage_staff",
            "pos_exit"
        ])
    }
}
