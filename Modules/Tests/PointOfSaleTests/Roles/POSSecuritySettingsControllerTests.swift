import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSSecuritySettingsControllerTests {
    private let storage = InMemoryPOSSecureStorage()
    private let defaultsScope = POSSecurityTestDefaults()

    @Test func test_setup_when_admin_is_saved_then_enables_protection_and_keeps_admin_active() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(controller.roles == [])
        #expect(controller.isVisible)

        // When
        let saved = await controller.save("1234", for: .admin)

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
        let saved = await controller.save("1234", for: .admin)

        // Then
        #expect(!saved)
        #expect(controller.error == .storageFailure)
        #expect(controller.roles == [])
        #expect(!session.isPINProtectionEnabled)
        #expect(!session.isLocked)
    }

    @Test func test_change_when_admin_matches_cashier_then_preserves_both_pins() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await controller.save("1234", for: .admin))
        #expect(await controller.save("5678", for: .cashier))

        // When
        let saved = await controller.save("5678", for: .admin)

        // Then
        #expect(!saved)
        #expect(controller.error == .pinMatchesOtherRole)
        #expect(controller.roles == [.admin, .cashier])
        #expect(session.currentStaff == POSLocalRole.admin.staff)
    }

    @Test func test_change_when_new_pin_is_saved_then_old_pin_stops_working() async throws {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await controller.save("1234", for: .admin))

        // When
        #expect(await controller.save("2468", for: .admin))
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
        #expect(await controller.save("1234", for: .admin))

        // When
        let saved = await controller.save("1234", for: .cashier)

        // Then
        #expect(!saved)
        #expect(controller.error == .pinMatchesOtherRole)
        #expect(controller.roles == [.admin])
        #expect(session.isPINProtectionEnabled)
    }

    @Test func test_remove_when_admin_is_removed_then_removes_both_pins_and_disables_protection() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await controller.save("1234", for: .admin))
        #expect(await controller.save("5678", for: .cashier))

        // When
        #expect(await controller.save(nil, for: .admin))

        // Then
        #expect(controller.roles == [])
        #expect(!session.isPINProtectionEnabled)
        #expect(!session.isLocked)
        #expect(session.currentStaff == nil)
        #expect(session.allows(.manageStoreSettings))
    }

    @Test func test_load_when_storage_is_unreadable_then_fails_closed() async {
        // Given
        let (controller, session, _) = makeSUT()
        controller.load()
        #expect(await controller.save("1234", for: .admin))
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
        #expect(await controller.save("1234", for: .admin))
        storage.shouldFailWrites = true

        // When
        let removed = await controller.save(nil, for: .admin)

        // Then
        #expect(!removed)
        #expect(controller.error == .storageFailure)
        #expect(session.isPINProtectionEnabled)
        #expect(!session.isLocked)
        #expect(controller.roles == [.admin])
        storage.shouldFailWrites = false
        controller.load()
        #expect(controller.roles == [.admin])
    }

    @Test func test_save_when_locked_or_cashier_then_does_not_change_credentials() async throws {
        // Given
        let (controller, session, store) = makeSUT()
        controller.load()
        #expect(await controller.save("1234", for: .admin))
        #expect(await controller.save("5678", for: .cashier))
        session.lock()

        // When / Then
        #expect(!controller.isVisible)
        #expect(await controller.save(nil, for: .admin) == false)
        try await session.signIn(withPIN: "5678")
        #expect(!controller.isVisible)
        #expect(await controller.save(nil, for: .admin) == false)
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
        if wasProtected { #expect(await controller.save("1234", for: .admin)) }
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
        #expect(await controller.save("2468", for: .admin) == false)
        #expect(storage.values == before)
        if let replacement {
            if wasProtected { try await replacement.signIn(withPIN: "1234") }
            #expect(replacement.allows(.manageStoreSettings))
        }
    }

    @Test func test_visibility_when_authority_changes_then_only_unlocked_admin_or_unprotected_can_manage() {
        // Given / When / Then
        #expect(POSSecuritySettingsViewHelper.canManage(isProtected: false, isLocked: false, canManageSettings: false))
        #expect(POSSecuritySettingsViewHelper.canManage(isProtected: true, isLocked: false, canManageSettings: true))
        #expect(!POSSecuritySettingsViewHelper.canManage(isProtected: true, isLocked: true, canManageSettings: true))
        #expect(!POSSecuritySettingsViewHelper.canManage(isProtected: true, isLocked: false, canManageSettings: false))
        #expect(!POSSecuritySettingsViewHelper.canManage(isProtected: false, isLocked: true, canManageSettings: true))
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
