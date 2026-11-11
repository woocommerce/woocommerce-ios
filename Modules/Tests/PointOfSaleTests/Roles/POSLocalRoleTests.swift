import Testing
@testable import PointOfSale

struct POSLocalRoleTests {
    @Test func test_staff_when_role_is_admin_then_has_every_capability() {
        // Given
        let sut = POSLocalRole.admin.staff

        // When / Then
        #expect(sut.capabilities == Set(POSCapability.allCases))
        #expect(sut.displayName == POSLocalRole.admin.displayName)
    }

    @Test func test_staff_when_role_is_cashier_then_can_sell_but_not_run_restricted_actions() {
        // Given
        let sut = POSLocalRole.cashier.staff

        // When / Then
        #expect(sut.capabilities == [.processSales, .viewOrders, .applyCoupons])
        #expect(sut.hasCapability(.createCoupons) == false)
        #expect(sut.hasCapability(.issueRefunds) == false)
        #expect(sut.hasCapability(.exitPOS) == false)
        #expect(sut.hasCapability(.manageStoreSettings) == false)
    }

    @Test func test_hasCapability_when_staff_has_a_custom_set_then_checks_only_that_set() {
        // Given
        let sut = POSStaff(displayName: "Maya", capabilities: [.issueRefunds])

        // When / Then
        #expect(sut.hasCapability(.issueRefunds))
        #expect(sut.hasCapability(.processSales) == false)
    }
}
