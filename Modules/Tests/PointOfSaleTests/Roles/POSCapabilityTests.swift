import Testing
@testable import PointOfSale

struct POSCapabilityTests {
    @Test func test_rawValues_match_backend_capability_identifiers() {
        // When / Then
        #expect(POSCapability.processSales.rawValue == "process_sales")
        #expect(POSCapability.viewOrders.rawValue == "view_orders")
        #expect(POSCapability.applyCoupons.rawValue == "apply_coupons")
        #expect(POSCapability.createCoupons.rawValue == "create_coupons")
        #expect(POSCapability.issueRefunds.rawValue == "issue_refunds")
        #expect(POSCapability.viewPOSSettings.rawValue == "view_pos_settings")
        #expect(POSCapability.editPOSSettings.rawValue == "edit_pos_settings")
        #expect(POSCapability.managePOSStaff.rawValue == "manage_pos_staff")
        #expect(POSCapability.exitPOS.rawValue == "exit_pos")
    }

    @Test func test_allCases_is_exactly_the_supported_capability_set() {
        // When / Then
        #expect(Set(POSCapability.allCases.map(\.rawValue)) == [
            "process_sales",
            "view_orders",
            "apply_coupons",
            "create_coupons",
            "issue_refunds",
            "view_pos_settings",
            "edit_pos_settings",
            "manage_pos_staff",
            "exit_pos"
        ])
    }
}
