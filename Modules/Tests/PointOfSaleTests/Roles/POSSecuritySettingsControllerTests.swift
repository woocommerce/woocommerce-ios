import Foundation
import Observation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSSecuritySettingsControllerTests {
    private let storage = InMemoryPOSSecureStorage()
    private let defaultsScope = POSSecurityTestDefaults()

    @Test func test_confirmation_when_other_role_changes_after_validation_then_final_save_still_rejects_duplicate() async throws {
        // Given
        let (controller, _, store) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        let setup = controller.makePINSetupController(for: .cashier)
        #expect(await setup.submit("5678") == .confirmationRequired)
        try store.setPIN("5678", for: .admin)

        // When
        let result = await setup.submit("5678")

        // Then
        #expect(result == .rejected)
        #expect(controller.error == .pinMatchesOtherRole)
        #expect(try store.configuredRoles() == [.admin])
    }

    @Test func test_first_entry_when_storage_is_unreadable_then_rejects_without_confirmation() async {
        // Given
        let (controller, _, _) = makeSUT()
        controller.load()
        let setup = controller.makePINSetupController(for: .admin)
        storage.shouldFail = true

        // When
        let result = await setup.submit("1234")

        // Then
        #expect(result == .rejected)
        #expect(setup.error == .storageFailure)
        #expect(!setup.isConfirmingPIN)
        #expect(storage.values.isEmpty)
    }

    @Test func test_setup_when_admin_is_saved_then_enables_protection_and_keeps_admin_active() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(controller.roles == [])
        #expect(controller.isVisible)

        // When
        let saved = await save("1234", for: .admin, using: controller)

        // Then
        #expect(saved)
        #expect(controller.roles == [.admin])
        #expect(session.isPINProtectionEnabled)
        #expect(session.currentStaff == POSLocalRole.admin.staff)
        #expect(!session.isLocked)
        #expect(controller.isVisible)
    }

    @Test func test_setup_when_first_write_fails_then_stays_unprotected_and_reports_failure() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        storage.shouldFailWrites = true

        // When
        let saved = await save("1234", for: .admin, using: controller)

        // Then
        #expect(!saved)
        #expect(controller.error == .storageFailure)
        #expect(controller.roles == [])
        #expect(!session.isPINProtectionEnabled)
        #expect(!session.isLocked)
    }

    @Test func test_cashier_setup_when_admin_pin_changes_then_only_offered_after_admin_setup() async {
        // Given
        let (controller, _, _) = makeSUT()
        controller.load()
        #expect(!controller.offersCashierPINSetup)
        #expect(!controller.hasOnlyAdminPIN)
        #expect(!controller.isPINProtectionEnabled)

        // When
        #expect(await save("1234", for: .admin, using: controller))

        // Then
        #expect(controller.offersCashierPINSetup)
        #expect(controller.hasOnlyAdminPIN)
        #expect(controller.isPINProtectionEnabled)
        #expect(await save("5678", for: .cashier, using: controller))
        #expect(controller.offersCashierPINSetup)
        #expect(!controller.hasOnlyAdminPIN)
        #expect(await removeProtection(using: controller))
        #expect(!controller.offersCashierPINSetup)
        #expect(!controller.hasOnlyAdminPIN)
        #expect(!controller.isPINProtectionEnabled)
    }

    @Test func test_change_when_admin_matches_cashier_then_preserves_both_pins() async throws {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))

        let (handler, approval) = await changeRequest(for: controller)
        #expect(await handler.submit(pin: "1234"))
        let setup = try #require(await approval.value)

        // When
        let result = await setup.submit("5678")

        // Then
        #expect(result == .rejected)
        #expect(!setup.isConfirmingPIN)
        #expect(setup.error == .pinMatchesOtherRole)
        #expect(controller.roles == [.admin, .cashier])
        #expect(session.currentStaff == POSLocalRole.admin.staff)
    }

    @Test func test_change_when_new_pin_is_saved_then_old_pin_stops_working() async throws {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))

        let (handler, approval) = await changeRequest(for: controller)
        #expect(await handler.submit(pin: "1234"))
        let setup = try #require(await approval.value)

        // When
        #expect(await setup.submit("2468") == .confirmationRequired)
        #expect(await setup.submit("2468") == .saved)
        session.lock()

        // Then
        await #expect(throws: POSAuthError.invalidPIN) { try await session.signIn(withPIN: "1234") }
        try await session.signIn(withPIN: "2468")
        #expect(session.currentStaff == POSLocalRole.admin.staff)
    }

    @Test func test_setup_when_cashier_pin_matches_admin_then_keeps_existing_credentials() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))

        // When
        let setup = controller.makePINSetupController(for: .cashier)
        let result = await setup.submit("1234")

        // Then
        #expect(result == .rejected)
        #expect(!setup.isConfirmingPIN)
        #expect(setup.error == .pinMatchesOtherRole)
        #expect(controller.roles == [.admin])
        #expect(session.isPINProtectionEnabled)
    }

    @Test func test_remove_when_admin_is_removed_then_removes_both_pins_and_disables_protection() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))

        // When
        #expect(await removeProtection(using: controller))

        // Then
        #expect(controller.roles == [])
        #expect(!session.isPINProtectionEnabled)
        #expect(!session.isLocked)
        #expect(session.currentStaff == nil)
        #expect(session.allows(.manageStoreSettings))
    }

    @Test func test_admin_removal_when_cancelled_then_preserves_both_pins() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))

        // When
        let (handler, approval) = await removalRequest(for: controller)
        #expect(controller.isApprovingProtectionRemoval)
        #expect(controller.roles == [.admin, .cashier])
        handler.cancel()

        // Then
        #expect(await approval.value == .cancelled)
        #expect(!controller.isApprovingProtectionRemoval)
        #expect(controller.roles == [.admin, .cashier])
        #expect(session.isPINProtectionEnabled)
    }

    @Test func test_admin_removal_when_approved_with_current_admin_pin_then_removes_both_pins() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))
        #expect(session.currentStaff == POSLocalRole.admin.staff)
        let (handler, approval) = await removalRequest(for: controller)

        // When
        let removed = await handler.submit(pin: "1234")

        // Then
        #expect(removed)
        #expect(await approval.value == .completed)
        #expect(!controller.isApprovingProtectionRemoval)
        #expect(handler.pinEntryState == .idle)
        #expect(controller.roles == [])
        #expect(!session.isPINProtectionEnabled)
        #expect(!session.isLocked)
    }

    @Test(arguments: ["0000", "5678"])
    func test_admin_removal_when_pin_is_not_the_admin_pin_then_preserves_both_pins(pin: String) async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))
        let (handler, approval) = await removalRequest(for: controller)

        // When
        let removed = await handler.submit(pin: pin)

        // Then
        #expect(!removed)
        #expect(controller.isApprovingProtectionRemoval)
        #expect(handler.pinEntryState == .error(kind: .invalidPIN))
        #expect(controller.roles == [.admin, .cashier])
        #expect(session.isPINProtectionEnabled)
        handler.cancel()
        #expect(await approval.value == .cancelled)
    }

    @Test func test_admin_removal_when_cancelled_during_pin_check_then_preserves_both_pins() async throws {
        // Given
        let store = POSLocalPINStore(siteID: 123, storage: storage, iterations: 1)
        try store.setPIN("1234", for: .admin)
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff)
        let controller = POSSecuritySettingsController(store: store, session: session)
        controller.load()
        let (handler, approval) = await removalRequest(for: controller)
        session.onManagerApproval = { handler.cancel() }

        // When
        let suppressFailureFeedback = await handler.submit(pin: "1234")

        // Then
        #expect(suppressFailureFeedback)
        #expect(await approval.value == .cancelled)
        #expect(session.managerApprovalCapabilities == [.manageStoreSettings])
        #expect(!controller.isApprovingProtectionRemoval)
        #expect(handler.pinEntryState == .idle)
        #expect(try store.configuredRoles() == [.admin])
    }

    @Test func test_admin_removal_when_not_requested_then_does_not_check_pin_or_remove() async throws {
        // Given
        let store = POSLocalPINStore(siteID: 123, storage: storage, iterations: 1)
        try store.setPIN("1234", for: .admin)
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff)
        let controller = POSSecuritySettingsController(store: store, session: session)
        controller.load()

        // When
        await controller.requestRemoval(for: .admin)

        // Then
        #expect(!controller.isApprovingProtectionRemoval)
        #expect(session.managerApprovalPINs.isEmpty)
        #expect(try store.configuredRoles() == [.admin])
    }

    @Test func test_cashier_removal_when_requested_then_removes_only_cashier_without_confirmation() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))

        // When
        await controller.requestRemoval(for: .cashier)

        // Then
        #expect(!controller.isApprovingProtectionRemoval)
        #expect(controller.roles == [.admin])
        #expect(session.isPINProtectionEnabled)
    }

    @Test func test_setup_flow_when_cashier_pin_duplicates_admin_then_rejects_until_distinct_pin_is_confirmed() async {
        // Given
        let (controller, _, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        let setup = controller.makePINSetupController(for: .cashier)
        // When
        #expect(await setup.submit("1234") == .rejected)

        // Then
        #expect(!setup.isConfirmingPIN)
        #expect(setup.error == .pinMatchesOtherRole)
        #expect(controller.roles == [.admin])
        #expect(await setup.submit("5678") == .confirmationRequired)
        #expect(await setup.submit("5678") == .saved)
        #expect(controller.roles == [.admin, .cashier])
    }

    @Test func test_load_when_storage_is_unreadable_then_fails_closed() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        storage.shouldFail = true

        // When
        controller.load()

        // Then
        #expect(controller.roles == nil)
        #expect(controller.error == .storageFailure)
        #expect(session.isPINProtectionEnabled)
        #expect(session.isLocked)
        #expect(!controller.isVisible)
        #expect(!session.allows(.manageStoreSettings))
    }

    @Test func test_save_when_storage_write_fails_then_does_not_report_success_or_disable_protection() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        storage.shouldFailWrites = true
        let (handler, approval) = await removalRequest(for: controller)

        // When
        let removed = await handler.submit(pin: "1234")

        // Then
        #expect(!removed)
        #expect(controller.error == .storageFailure)
        #expect(session.isPINProtectionEnabled)
        #expect(!session.isLocked)
        #expect(controller.roles == [.admin])
        #expect(controller.isApprovingProtectionRemoval)
        storage.shouldFailWrites = false
        #expect(await handler.submit(pin: "1234"))
        #expect(await approval.value == .completed)
        #expect(controller.roles == [])
    }

    @Test func test_save_when_locked_or_cashier_then_does_not_change_credentials() async throws {
        // Given
        let (controller, session, store) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))
        session.lock()

        // When / Then
        #expect(!controller.isVisible)
        #expect(await removeProtection(using: controller) == false)
        try await session.signIn(withPIN: "5678")
        #expect(!controller.isVisible)
        #expect(await removeProtection(using: controller) == false)
        #expect(try store.credentials().count == 2)
    }

    @Test(arguments: [POSLocalRole.admin, .cashier])
    func test_role_display_names_when_local_roles_then_maps_to_current_names(role: POSLocalRole) {
        // Given / When / Then
        #expect(role.displayName == (role == .admin ? "Admin" : "Cashier"))
    }

    @Test(arguments: [false, true], [false, true])
    func test_save_when_session_is_replaced_or_ended_then_cannot_mutate_pins(wasProtected: Bool, endOnly: Bool) async throws {
        // Given
        let store = POSLocalPINStore(siteID: 123, storage: storage, iterations: 1)
        let limiter = POSLocalRateLimiter(siteID: 123, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock())
        let session = DefaultPOSAccessSession(siteID: 123, authenticator: DefaultPOSPINAuthenticator(credentialProvider: store),
                                              rateLimiter: limiter, credentialProvider: store, userDefaults: defaultsScope.defaults)
        let controller = POSSecuritySettingsController(store: store, session: session)
        controller.load()
        if wasProtected { #expect(await save("1234", for: .admin, using: controller)) }
        let before = storage.values
        let replacement: DefaultPOSAccessSession?

        // When
        if endOnly {
            session.endSession()
            replacement = nil
        } else {
            replacement = DefaultPOSAccessSession(siteID: 123, authenticator: DefaultPOSPINAuthenticator(credentialProvider: store),
                                                  rateLimiter: limiter, credentialProvider: store, userDefaults: defaultsScope.defaults)
        }

        // Then
        #expect(controller.isVisible == false)
        #expect(await save("2468", for: .admin, using: controller) == false)
        #expect(storage.values == before)
        if let replacement {
            if wasProtected { try await replacement.signIn(withPIN: "1234") }
            #expect(replacement.allows(.manageStoreSettings))
        }
    }

    @Test func test_removal_when_already_admin_then_verifies_once_and_rejects_concurrent_submissions() async throws {
        // Given
        let store = POSLocalPINStore(siteID: 123, storage: storage, iterations: 1)
        try store.setPIN("1234", for: .admin)
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff)
        let controller = POSSecuritySettingsController(store: store, session: session)
        controller.load()
        let (handler, approval) = await removalRequest(for: controller)
        session.onManagerApproval = {
            #expect(await handler.submit(pin: "1234") == false)
        }

        // When
        #expect(await handler.submit(pin: "1234"))

        // Then
        #expect(session.managerApprovalPINs == ["1234"])
        #expect(session.managerApprovalCapabilities == [.manageStoreSettings])
        #expect(session.signInPINs.isEmpty)
        #expect(await approval.value == .completed)
        #expect(handler.request == nil)
    }

    @Test(arguments: [0, 1, 2, 3])
    func test_removal_when_approval_loses_admission_then_late_success_preserves_pins(change: Int) async throws {
        // Given
        let store = POSLocalPINStore(siteID: 123, storage: storage, iterations: 1)
        try store.setPIN("1234", for: .admin)
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff)
        let controller = POSSecuritySettingsController(store: store, session: session)
        controller.load()
        let (handler, approval) = await removalRequest(for: controller)
        var replacement: Task<POSManagerOverrideHandler.ApprovalResult, Never>?
        session.onManagerApproval = {
            switch change {
            case 0:
                (_, replacement) = await removalRequest(for: controller, using: handler)
            case 1: session.lock()
            case 2: session.currentStaff = POSLocalRole.cashier.staff
            default: approval.cancel()
            }
        }

        // When
        _ = await handler.submit(pin: "1234")

        // Then
        #expect(try store.configuredRoles() == [.admin])
        #expect(session.managerApprovalPINs == ["1234"])
        handler.cancel()
        #expect(await approval.value == .cancelled)
        if let replacement { #expect(await replacement.value == .cancelled) }
    }

    @Test func test_removal_when_pos_locks_and_admin_unlocks_before_approval_then_preserves_pins() async throws {
        // Given
        let (controller, session, store) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        let (handler, approval) = await removalRequest(for: controller)

        // When
        session.lock()
        try await session.signIn(withPIN: "1234")
        _ = await handler.submit(pin: "1234")

        // Then
        #expect(try store.configuredRoles() == [.admin])
        #expect(session.isPINProtectionEnabled)
        handler.cancel()
        #expect(await approval.value == .cancelled)
    }

    @Test func test_removal_when_caller_is_cancelled_before_entry_then_does_not_present_or_write() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        let handler = POSManagerOverrideHandler()
        let approval = Task { await controller.requestProtectionRemoval(using: handler, reason: "Remove both PINs") }

        // When
        approval.cancel()

        // Then
        #expect(await approval.value == .cancelled)
        #expect(handler.request == nil)
        #expect(!controller.isApprovingProtectionRemoval)
        #expect(controller.roles == [.admin])
        #expect(session.isPINProtectionEnabled)
    }

    @Test func test_removal_when_shared_attempt_budget_is_exhausted_then_keeps_setup_and_requires_wait() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        let (handler, approval) = await removalRequest(for: controller)
        for _ in 0..<5 { #expect(await handler.submit(pin: "0000") == false) }

        // When / Then
        guard case .waiting = handler.pinEntryState else { Issue.record("Expected the approval countdown"); return }
        #expect(POSPINEntryViewHelper().isInputEnabled(for: handler.pinEntryState) == false)
        #expect(await handler.submit(pin: "1234") == false)
        #expect(handler.request != nil)
        do {
            try await session.signIn(withPIN: "1234")
            Issue.record("Expected unlock to use the same wait")
        } catch {
            guard case .rateLimited = error else { Issue.record("Expected a rate-limited error"); return }
        }
        #expect(controller.roles == [.admin])
        #expect(controller.isPINProtectionEnabled)
        #expect(controller.isApprovingProtectionRemoval)
        handler.cancel()
        #expect(await approval.value == .cancelled)
    }

    @Test func test_admin_change_when_approved_then_preserves_role_and_replaces_only_after_confirmation_once() async throws {
        // Given
        let (controller, session, store) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))
        let before = try store.credentials()
        let scope = session.accessScope
        let (handler, approval) = await changeRequest(for: controller)

        // When
        #expect(await handler.submit(pin: "1234"))
        let setup = try #require(await approval.value)

        // Then
        #expect(session.currentStaff == POSLocalRole.admin.staff)
        #expect(session.accessScope == scope)
        #expect(!controller.isApprovingProtectionRemoval)
        #expect(try store.credentials() == before)
        #expect(await setup.submit("2468") == .confirmationRequired)
        #expect(try store.credentials() == before)
        #expect(await setup.submit("2468") == .saved)
        let after = try store.credentials()
        #expect(after.first { $0.staff == POSLocalRole.admin.staff }?.pinHash.matches("2468") == true)
        #expect(after.first { $0.staff == POSLocalRole.admin.staff }?.pinHash.matches("1234") == false)
        #expect(after.first { $0.staff == POSLocalRole.cashier.staff } == before.first { $0.staff == POSLocalRole.cashier.staff })
        #expect(await setup.submit("1357") == .rejected)
        session.lock()
        try await session.signIn(withPIN: "2468")
        #expect(session.currentStaff == POSLocalRole.admin.staff)
    }

    @Test func test_admin_change_when_no_fresh_approval_then_cannot_start_editor() async {
        // Given
        let (controller, _, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        let before = storage.values

        // When / Then
        #expect(await save("2468", for: .admin, using: controller) == false)
        #expect(storage.values == before)
    }

    @Test(arguments: ["0000", "5678"])
    func test_admin_change_when_wrong_or_cashier_pin_then_rejects_without_changing_credentials(pin: String) async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))
        let before = storage.values
        let (handler, approval) = await changeRequest(for: controller)

        // When
        #expect(await handler.submit(pin: pin) == false)
        handler.cancel()

        // Then
        #expect(await approval.value == nil)
        #expect(storage.values == before)
        #expect(session.currentStaff == POSLocalRole.admin.staff)
    }

    @Test func test_admin_change_when_attempt_budget_is_exhausted_then_shares_unlock_wait() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        let before = storage.values
        let (handler, approval) = await changeRequest(for: controller)

        // When
        for _ in 0..<5 { #expect(await handler.submit(pin: "0000") == false) }

        // Then
        guard case .waiting = handler.pinEntryState else { Issue.record("Expected shared cooldown"); handler.cancel(); return }
        #expect(await handler.submit(pin: "1234") == false)
        do {
            try await session.signIn(withPIN: "1234")
            Issue.record("Expected shared cooldown at unlock")
        } catch {
            guard case .rateLimited = error else { Issue.record("Expected rate limited"); handler.cancel(); return }
        }
        handler.cancel()
        #expect(await approval.value == nil)
        #expect(storage.values == before)
    }

    @Test(arguments: [0, 1, 2, 3])
    func test_admin_change_when_approval_loses_admission_then_does_not_return_editor(change: Int) async throws {
        // Given
        let store = POSLocalPINStore(siteID: 123, storage: storage, iterations: 1)
        try store.setPIN("1234", for: .admin)
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff)
        let controller = POSSecuritySettingsController(store: store, session: session, lockSettings: makeLockSettings())
        controller.load()
        let before = storage.values
        let (handler, approval) = await changeRequest(for: controller)
        session.onManagerApproval = {
            switch change {
            case 0: session.lock()
            case 1: session.endSession()
            case 2: approval.cancel()
            default: handler.cancel()
            }
        }

        // When
        _ = await handler.submit(pin: "1234")
        handler.cancel()

        // Then
        #expect(await approval.value == nil)
        #expect(session.managerApprovalPINs == ["1234"])
        #expect(session.signInPINs.isEmpty)
        #expect(storage.values == before)
    }

    @Test(arguments: [POSLocalRole.admin, .cashier])
    func test_replacement_when_write_fails_then_keeps_old_pin_and_retry_requires_confirmation(role: POSLocalRole) async throws {
        // Given
        let (controller, _, store) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))
        let setup: POSPINSetupController
        if role == .admin {
            let (handler, approval) = await changeRequest(for: controller)
            #expect(await handler.submit(pin: "1234"))
            setup = try #require(await approval.value)
        } else {
            setup = controller.makePINSetupController(for: .cashier)
        }
        let before = try store.credentials()
        #expect(await setup.submit("2468") == .confirmationRequired)
        storage.shouldFailWrites = true

        // When
        #expect(await setup.submit("2468") == .rejected)

        // Then
        #expect(try store.credentials() == before)
        #expect(controller.error == .storageFailure)
        storage.shouldFailWrites = false
        #expect(await setup.submit("2468") == .confirmationRequired)
        #expect(await setup.submit("2468") == .saved)
    }

    @Test(arguments: [0, 1, 2])
    func test_cashier_editor_when_scope_changes_before_confirmation_then_keeps_existing_pin(change: Int) async throws {
        // Given
        let (controller, session, store) = makeSUT()
        controller.load()
        #expect(await save("1234", for: .admin, using: controller))
        #expect(await save("5678", for: .cashier, using: controller))
        let setup = controller.makePINSetupController(for: .cashier)
        #expect(await setup.submit("2468") == .confirmationRequired)
        let before = try store.credentials()

        // When
        switch change {
        case 0:
            session.lock()
            try await session.signIn(withPIN: "1234")
        case 1: controller.endPINEditing()
        default: _ = controller.makePINSetupController(for: .cashier)
        }

        // Then
        #expect(await setup.submit("2468") == .rejected)
        #expect(try store.credentials() == before)
    }

    @Test(arguments: [POSLocalRole.admin, .cashier], [0, 1, 2, 3, 4])
    func test_replacement_when_preparation_becomes_stale_then_does_not_commit(role: POSLocalRole, change: Int) async throws {
        // Given
        let (original, session, store) = makeSUT()
        original.load()
        #expect(await save("1234", for: .admin, using: original))
        #expect(await save("5678", for: .cashier, using: original))
        let blocking = MockBlockingPOSPINStore(store: store)
        let controller = POSSecuritySettingsController(store: blocking, session: session, lockSettings: makeLockSettings())
        controller.load()
        let setup: POSPINSetupController
        if role == .admin {
            let (handler, approval) = await changeRequest(for: controller)
            #expect(await handler.submit(pin: "1234"))
            setup = try #require(await approval.value)
        } else {
            setup = controller.makePINSetupController(for: .cashier)
        }
        #expect(await setup.submit("2468") == .confirmationRequired)
        let before = try store.credentials()
        let save = Task { await setup.submit("2468") }
        defer { blocking.releaseMutation() }
        try await blocking.waitUntilEntered()

        // When
        switch change {
        case 0:
            session.lock()
            try await session.signIn(withPIN: "1234")
        case 1: session.endSession()
        case 2: setup.discardDraft()
        case 3: controller.endPINEditing()
        default: save.cancel()
        }
        blocking.releaseMutation()

        // Then
        #expect(await save.value == .rejected)
        #expect(try store.credentials() == before)
    }

    private func changeRequest(for controller: POSSecuritySettingsController) async
        -> (POSManagerOverrideHandler, Task<POSPINSetupController?, Never>) {
        let handler = POSManagerOverrideHandler()
        let (ready, input) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        withObservationTracking { _ = handler.request } onChange: { input.yield(()) }
        let approval = Task { await controller.requestAdminPINChange(using: handler, reason: "Change Admin PIN") }
        var readiness = ready.makeAsyncIterator()
        _ = await readiness.next()
        input.finish()
        return (handler, approval)
    }

    private func removalRequest(for controller: POSSecuritySettingsController,
                                using suppliedHandler: POSManagerOverrideHandler? = nil) async
        -> (POSManagerOverrideHandler, Task<POSManagerOverrideHandler.ApprovalResult, Never>) {
        let handler = suppliedHandler ?? POSManagerOverrideHandler()
        let (ready, input) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        withObservationTracking { _ = handler.request } onChange: { input.yield(()) }
        let approval = Task {
            let result = await controller.requestProtectionRemoval(using: handler, reason: "Remove both PINs")
            input.yield(())
            return result
        }
        var readiness = ready.makeAsyncIterator()
        _ = await readiness.next()
        input.finish()
        return (handler, approval)
    }

    private func removeProtection(using controller: POSSecuritySettingsController) async -> Bool {
        let (handler, approval) = await removalRequest(for: controller)
        if handler.request != nil {
            _ = await handler.submit(pin: "1234")
            if handler.request != nil { handler.cancel() }
        }
        return await approval.value == .completed
    }

    private func save(_ pin: String, for role: POSLocalRole, using controller: POSSecuritySettingsController) async -> Bool {
        let setup = controller.makePINSetupController(for: role)
        guard await setup.submit(pin) == .confirmationRequired else { return false }
        return await setup.submit(pin) == .saved
    }

    private func makeSUT() -> (POSSecuritySettingsController, DefaultPOSAccessSession, POSLocalPINStore) {
        let store = POSLocalPINStore(siteID: 123, storage: storage, iterations: 1)
        let defaults = defaultsScope.defaults
        let session = DefaultPOSAccessSession(siteID: 123,
                                             authenticator: DefaultPOSPINAuthenticator(credentialProvider: store),
                                             rateLimiter: POSLocalRateLimiter(siteID: 123, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock()),
                                             credentialProvider: store,
                                             userDefaults: defaults)
        return (POSSecuritySettingsController(store: store, session: session), session, store)
    }
}

private final class POSSecurityTestDefaults {
    let defaults: UserDefaults
    private let name = "POSSecurityTests.\(UUID().uuidString)"
    init() { defaults = UserDefaults(suiteName: name)! }
    deinit { defaults.removePersistentDomain(forName: name) }
}
