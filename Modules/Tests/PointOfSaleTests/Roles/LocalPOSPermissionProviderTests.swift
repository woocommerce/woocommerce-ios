import Testing
import enum Networking.POSAuthError
@testable import PointOfSale

struct LocalPOSPermissionProviderTests {

    // MARK: - checkPermission

    @Test func test_checkPermission_when_not_locked_and_operator_has_capability_then_returns_allowed() {
        // Given
        let sut = makeSUT()
        let op = makeManagerOperator()
        sut.signIn(op)

        // When
        let result = sut.checkPermission("woocommerce_pos_access")

        // Then
        #expect(result == .allowed)
    }

    @Test func test_checkPermission_when_manager_signed_in_then_returns_allowed_for_manager_capability() {
        // Given
        let sut = makeSUT()
        let op = makeManagerOperator()
        sut.signIn(op)

        // When
        let result = sut.checkPermission("woocommerce_refund_orders")

        // Then
        #expect(result == .allowed)
    }

    @Test func test_checkPermission_when_cashier_signed_in_then_returns_requiresOverride_for_manager_capability() {
        // Given
        let sut = makeSUT()
        let op = makeCashierOperator()
        sut.signIn(op)

        // When
        let result = sut.checkPermission("woocommerce_refund_orders")

        // Then
        #expect(result == .requiresOverride)
    }

    @Test func test_checkPermission_when_cashier_signed_in_then_returns_allowed_for_cashier_capability() {
        // Given
        let sut = makeSUT()
        let op = makeCashierOperator()
        sut.signIn(op)

        // When
        let result = sut.checkPermission("woocommerce_pos_access")

        // Then
        #expect(result == .allowed)
    }

    @Test func test_checkPermission_when_no_operator_then_returns_requiresOverride() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.checkPermission("woocommerce_pos_access")

        // Then
        #expect(result == .requiresOverride)
    }

    // MARK: - hasCapability

    @Test func test_hasCapability_when_operator_has_it_then_returns_true() {
        // Given
        let sut = makeSUT()
        sut.signIn(makeManagerOperator())

        // When / Then
        #expect(sut.hasCapability("woocommerce_pos_access") == true)
    }

    @Test func test_hasCapability_when_operator_lacks_it_then_returns_false() {
        // Given
        let sut = makeSUT()
        sut.signIn(makeCashierOperator())

        // When / Then
        #expect(sut.hasCapability("woocommerce_refund_orders") == false)
    }

    @Test func test_hasCapability_when_no_operator_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.hasCapability("woocommerce_pos_access") == false)
    }

    // MARK: - signIn

    @Test func test_signIn_sets_currentOperator_and_clears_isLocked() {
        // Given
        let sut = makeSUT()
        sut.lock()

        // When
        sut.signIn(makeManagerOperator())

        // Then
        #expect(sut.currentOperator != nil)
        #expect(sut.isLocked == false)
    }

    // MARK: - lock

    @Test func test_lock_clears_operator_and_sets_isLocked() {
        // Given
        let sut = makeSUT()
        sut.signIn(makeManagerOperator())

        // When
        sut.lock()

        // Then
        #expect(sut.currentOperator == nil)
        #expect(sut.isLocked == true)
    }

    // MARK: - authenticatePIN

    @Test func test_authenticatePIN_when_manager_pin_matches_then_signs_in_as_manager() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        let sut = makeSUT(pinService: pinService)

        // When
        let op = sut.authenticatePIN("1234")

        // Then
        #expect(op != nil)
        #expect(op?.role == "pos_manager")
        #expect(op?.isAppAccountHolder == true)
        #expect(op?.userID == 42)
        #expect(op?.displayName == "Store Owner")
        #expect(op?.capabilities == LocalPOSPermissionProvider.adminCapabilities)
        #expect(sut.currentOperator == op)
        #expect(sut.isLocked == false)
    }

    @Test func test_authenticatePIN_when_cashier_pin_matches_then_signs_in_as_cashier() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("5678", for: .cashier)
        let sut = makeSUT(pinService: pinService)

        // When
        let op = sut.authenticatePIN("5678")

        // Then
        #expect(op != nil)
        #expect(op?.role == "pos_cashier")
        #expect(op?.isAppAccountHolder == false)
        #expect(op?.userID == 0)
        #expect(op?.displayName == "Cashier")
        #expect(op?.capabilities == LocalPOSPermissionProvider.cashierCapabilities)
        #expect(sut.currentOperator == op)
    }

    @Test func test_authenticatePIN_when_locked_and_valid_pin_then_unlocks() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        let sut = makeSUT(pinService: pinService)
        sut.lock()
        #expect(sut.isLocked == true)
        #expect(sut.currentOperator == nil)

        // When
        let op = sut.authenticatePIN("1234")

        // Then
        #expect(op != nil)
        #expect(sut.isLocked == false)
        #expect(sut.currentOperator != nil)
    }

    @Test func test_authenticatePIN_when_no_match_then_returns_nil() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        let sut = makeSUT(pinService: pinService)

        // When
        let op = sut.authenticatePIN("9999")

        // Then
        #expect(op == nil)
        #expect(sut.currentOperator == nil)
    }

    // MARK: - verifyManagerPIN

    @Test func test_verifyManagerPIN_when_correct_then_returns_true() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        let sut = makeSUT(pinService: pinService)

        // When / Then
        #expect(sut.verifyManagerPIN("1234") == true)
    }

    @Test func test_verifyManagerPIN_when_wrong_then_returns_false() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        let sut = makeSUT(pinService: pinService)

        // When / Then
        #expect(sut.verifyManagerPIN("9999") == false)
    }

    @Test func test_verifyManagerPIN_when_cashier_pin_then_returns_false() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("5678", for: .cashier)
        let sut = makeSUT(pinService: pinService)

        // When / Then
        #expect(sut.verifyManagerPIN("5678") == false)
    }

    // MARK: - verifyAccountHolderPIN

    @Test func test_verifyAccountHolderPIN_when_manager_pin_correct_then_returns_true() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        let sut = makeSUT(pinService: pinService)

        // When / Then
        #expect(sut.verifyAccountHolderPIN("1234") == true)
    }

    @Test func test_verifyAccountHolderPIN_when_wrong_then_returns_false() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        let sut = makeSUT(pinService: pinService)

        // When / Then
        #expect(sut.verifyAccountHolderPIN("9999") == false)
    }

    // MARK: - requestManagerApproval

    @Test func test_requestManagerApproval_when_manager_pin_is_valid_then_returns_nil_token() async throws {
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        let sut = makeSUT(pinService: pinService)

        let token = try await sut.requestManagerApproval(
            managerPIN: "1234",
            for: "woocommerce_refund_orders",
            orderID: 42
        )

        #expect(token == nil)
    }

    @Test func test_requestManagerApproval_when_manager_pin_is_invalid_then_throws_invalid_pin() async {
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        let sut = makeSUT(pinService: pinService)

        await #expect(throws: POSAuthError.invalidPIN) {
            try await sut.requestManagerApproval(
                managerPIN: "9999",
                for: "woocommerce_refund_orders",
                orderID: 42
            )
        }
    }

    // MARK: - hasAnyPINs

    @Test func test_hasAnyPINs_when_no_pins_configured_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.hasAnyPINs == false)
    }

    @Test func test_hasAnyPINs_when_manager_pin_set_then_returns_true() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        let sut = makeSUT(pinService: pinService)

        // When / Then
        #expect(sut.hasAnyPINs == true)
    }

    @Test func test_hasAnyPINs_when_cashier_pin_set_then_returns_true() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("5678", for: .cashier)
        let sut = makeSUT(pinService: pinService)

        // When / Then
        #expect(sut.hasAnyPINs == true)
    }

    // MARK: - Capability Sets

    @Test func test_adminCapabilities_contains_expected_capabilities() {
        // Then
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_pos_access"))
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_pos_read_settings"))
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_pos_write_settings"))
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_void_orders"))
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_refund_orders"))
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_apply_discounts"))
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_override_prices"))
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_view_sales_reports"))
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_edit_customer_data"))
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_adjust_stock"))
        #expect(LocalPOSPermissionProvider.adminCapabilities.contains("woocommerce_view_audit_logs"))
    }

    @Test func test_cashierCapabilities_is_subset_of_adminCapabilities() {
        // Then
        #expect(LocalPOSPermissionProvider.cashierCapabilities
            .isSubset(of: LocalPOSPermissionProvider.adminCapabilities))
    }

    @Test func test_cashierCapabilities_does_not_include_refund_orders() {
        // Then
        #expect(LocalPOSPermissionProvider.cashierCapabilities.contains("woocommerce_refund_orders") == false)
    }

    // MARK: - Helpers

    private func makePINService() -> POSPINService {
        POSPINService(storage: InMemoryPINStorage())
    }

    private func makeSUT(pinService: POSPINService? = nil) -> LocalPOSPermissionProvider {
        let service = pinService ?? makePINService()
        return LocalPOSPermissionProvider(
            pinService: service,
            appAccountUserID: 42,
            appAccountDisplayName: "Store Owner"
        )
    }

    private func makeManagerOperator() -> POSOperator {
        POSOperator(
            userID: 42,
            displayName: "Store Owner",
            role: "pos_manager",
            capabilities: LocalPOSPermissionProvider.adminCapabilities,
            isAppAccountHolder: true
        )
    }

    private func makeCashierOperator() -> POSOperator {
        POSOperator(
            userID: 0,
            displayName: "Cashier",
            role: "pos_cashier",
            capabilities: LocalPOSPermissionProvider.cashierCapabilities,
            isAppAccountHolder: false
        )
    }
}
