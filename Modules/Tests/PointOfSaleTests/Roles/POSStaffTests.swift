import Testing
@testable import PointOfSale

struct POSStaffTests {
    @Test func test_capabilities_when_role_is_admin_then_has_every_capability() {
        // Given
        let sut = POSStaff(role: .admin)

        // When / Then
        #expect(sut.capabilities == Set(POSCapability.allCases))
    }

    @Test func test_capabilities_when_role_is_cashier_then_can_sell_but_not_run_restricted_actions() {
        // Given
        let sut = POSStaff(role: .cashier)

        // When / Then
        #expect(sut.capabilities == [.processSales, .viewOrders, .applyCoupons])
        #expect(sut.hasCapability(.createCoupons) == false)
        #expect(sut.hasCapability(.issueRefunds) == false)
        #expect(sut.hasCapability(.exitPOS) == false)
        #expect(sut.hasCapability(.manageStoreSettings) == false)
    }

    @Test func test_hasCapability_when_capabilities_are_given_then_they_replace_the_role_set() {
        // Given
        let sut = POSStaff(role: .cashier, capabilities: [.issueRefunds])

        // When / Then
        #expect(sut.hasCapability(.issueRefunds))
        #expect(sut.hasCapability(.processSales) == false)
    }
}
