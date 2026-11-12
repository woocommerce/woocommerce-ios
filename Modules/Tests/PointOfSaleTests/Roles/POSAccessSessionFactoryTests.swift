import Foundation
import Testing
import enum Experiments.FeatureFlag
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSAccessSessionFactoryTests {
    @Test func test_make_when_flag_is_off_then_returns_unrestricted_session() async throws {
        // Given
        let flags = StubPOSFeatureFlagProviding(enabledFlags: [])

        // When
        let session = try await POSAccessSessionFactory.make(siteID: 123, featureFlags: flags)

        // Then
        #expect(session is UnrestrictedPOSAccessSession)
        #expect(session.allows(.manageStoreSettings))
    }

    @Test func test_make_when_flag_is_on_and_no_pin_then_returns_current_unprotected_session() async throws {
        // Given
        let sut = makeSUT()

        // When
        let session = try await makeReplacement(sut)

        // Then
        #expect(session is DefaultPOSAccessSession)
        #expect(session.isPINProtectionEnabled == false)
        #expect(session.allows(.manageStoreSettings))
    }

    @Test(arguments: ["setup", "remove", "failure"])
    func test_make_when_pin_mutation_is_pending_then_waits_for_committed_protection(operation: String) async throws {
        // Given
        let sut = makeSUT(fails: operation == "failure")
        if operation == "remove" {
            try sut.store.setPIN("1234", for: .admin)
            try sut.session.refreshPINProtection()
            try await sut.session.signIn(withPIN: "1234")
        }
        sut.controller.load()
        let save = Task { await sut.controller.save(operation == "remove" ? nil : "1234", for: .admin) }
        defer { sut.blocking.releaseMutation() }
        try await sut.blocking.waitUntilEntered()
        #expect(sut.limiter.context.hasPendingPINChanges)
        var started = false
        var constructed = false

        // When
        let replacement = Task {
            started = true
            let session = try await makeReplacement(sut)
            constructed = true
            return session
        }
        while !started { await Task.yield() }

        // Then: an unrelated store is not blocked by this store's mutation.
        #expect(constructed == false)
        let other = makeSUT(siteID: 124)
        #expect(try await makeReplacement(other).isPINProtectionEnabled == false)
        sut.blocking.releaseMutation()
        #expect(await save.value == (operation != "failure"))
        let current = try await replacement.value
        #expect(current.isPINProtectionEnabled == (operation == "setup"))
        #expect(current.isLocked == (operation == "setup"))
        #expect(sut.limiter.context.hasPendingPINChanges == false)
    }

    @Test func test_cancellation_when_worker_is_pending_then_neither_publishes_owner_nor_releases_mutation_early() async throws {
        // Given
        let sut = makeSUT()
        sut.controller.load()
        let save = Task { await sut.controller.save("1234", for: .admin) }
        defer { sut.blocking.releaseMutation() }
        try await sut.blocking.waitUntilEntered()
        let token = sut.limiter.context.current()
        let marker = sut.defaults.defaults.object(forKey: POSLockStateKey.key(for: 123)) as? Bool
        var started = false
        let replacement = Task {
            started = true
            return try await makeReplacement(sut)
        }
        while !started { await Task.yield() }

        // When
        replacement.cancel()
        save.cancel()
        await #expect(throws: CancellationError.self) { try await replacement.value }

        // Then
        #expect(sut.limiter.context.hasPendingPINChanges)
        #expect(sut.limiter.context.isCurrent(token))
        #expect(sut.defaults.defaults.object(forKey: POSLockStateKey.key(for: 123)) as? Bool == marker)
        sut.blocking.releaseMutation()
        #expect(await save.value)
        #expect(sut.limiter.context.hasPendingPINChanges == false)
        #expect(sut.session.currentStaff == POSLocalRole.admin.staff)
    }

    @Test func test_make_when_already_cancelled_then_does_not_claim_owner_or_write_marker() async {
        // Given
        let sut = makeSUT()
        let token = sut.limiter.context.current()
        let marker = sut.defaults.defaults.object(forKey: POSLockStateKey.key(for: 123)) as? Bool
        let task = Task { try await makeReplacement(sut) }
        task.cancel()

        // When / Then
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(sut.limiter.context.isCurrent(token))
        #expect(sut.defaults.defaults.object(forKey: POSLockStateKey.key(for: 123)) as? Bool == marker)
    }

    @Test func test_two_entrants_when_pending_change_finishes_then_only_needed_entry_can_claim_owner() async throws {
        // Given
        let sut = makeSUT()
        sut.controller.load()
        let save = Task { await sut.controller.save("1234", for: .admin) }
        defer { sut.blocking.releaseMutation() }
        try await sut.blocking.waitUntilEntered()
        var needed = true
        var started = 0
        @MainActor func enter() async throws -> POSAccessSession {
            started += 1
            let session = try await makeReplacement(sut, shouldCreate: { needed })
            needed = false
            return session
        }
        let first = Task { try await enter() }
        let second = Task { try await enter() }
        while started < 2 { await Task.yield() }

        // When
        sut.blocking.releaseMutation()
        #expect(await save.value)
        let results = [await first.result, await second.result]
        let sessions = results.compactMap { try? $0.get() }

        // Then
        #expect(sessions.count == 1)
        let mounted = try #require(sessions.first)
        try await mounted.checkLockoutState()
        try await mounted.signIn(withPIN: "1234")
        #expect(mounted.allows(.manageStoreSettings))
    }
}

private extension POSAccessSessionFactoryTests {
    struct SUT {
        let siteID: Int64
        let store: POSLocalPINStore
        let blocking: MockBlockingPOSPINStore
        let limiter: POSLocalRateLimiter
        let session: DefaultPOSAccessSession
        let controller: POSSecuritySettingsController
        let defaults: FactoryTestDefaults
    }

    func makeSUT(fails: Bool = false, siteID: Int64 = 123) -> SUT {
        let store = POSLocalPINStore(siteID: siteID, storage: InMemoryPOSSecureStorage(), iterations: 1)
        let blocking = MockBlockingPOSPINStore(store: store, fails: fails)
        let limiter = POSLocalRateLimiter(siteID: siteID, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock())
        let defaults = FactoryTestDefaults()
        let session = DefaultPOSAccessSession(siteID: siteID, authenticator: DefaultPOSPINAuthenticator(credentialProvider: store),
                                              rateLimiter: limiter, credentialProvider: store, userDefaults: defaults.defaults)
        return SUT(siteID: siteID, store: store, blocking: blocking, limiter: limiter, session: session,
                   controller: POSSecuritySettingsController(store: blocking, session: session), defaults: defaults)
    }

    func makeReplacement(_ sut: SUT, shouldCreate: @MainActor () -> Bool = { true }) async throws -> POSAccessSession {
        try await POSAccessSessionFactory.make(siteID: sut.siteID, featureFlags: StubPOSFeatureFlagProviding(enabledFlags: [.pointOfSaleRoles]),
                                               credentialProvider: sut.store, rateLimiter: sut.limiter, userDefaults: sut.defaults.defaults,
                                               shouldCreate: shouldCreate)
    }
}

private final class FactoryTestDefaults {
    let defaults: UserDefaults
    private let name = "POSFactoryTests." + UUID().uuidString
    init() { defaults = UserDefaults(suiteName: name)! }
    deinit { defaults.removePersistentDomain(forName: name) }
}

private final class StubPOSFeatureFlagProviding: POSFeatureFlagProviding {
    let enabledFlags: Set<FeatureFlag>

    init(enabledFlags: Set<FeatureFlag>) { self.enabledFlags = enabledFlags }
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool { enabledFlags.contains(flag) }
}
