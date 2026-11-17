import Foundation
import Observation
import Testing
import UIKit
import enum Experiments.FeatureFlag
@testable import PointOfSale

@MainActor
@Suite(.serialized, .timeLimit(.minutes(5)))
struct POSAccessSessionFactoryTests {
    @Test(arguments: [false, true])
    func test_validation_when_session_is_retired_then_does_not_restore_draft_or_block_replacement(endOnly: Bool) async throws {
        // Given
        let sut = makeSUT(blocksValidation: true)
        sut.controller.load()
        let setup = sut.controller.makePINSetupController(for: .admin)
        let entry = Task { await setup.submit("1234") }
        defer { sut.blocking.releaseMutation() }
        try await sut.blocking.waitUntilEntered()
        #expect(sut.limiter.pendingPINChanges.isEmpty)

        // When
        let replacement: POSAccessSession?
        if endOnly {
            sut.session.endSession()
            replacement = nil
        } else {
            replacement = try await makeReplacement(sut)
        }
        sut.blocking.releaseMutation()

        // Then
        #expect(await entry.value == .rejected)
        #expect(setup.error == nil)
        #expect(try sut.store.configuredRoles().isEmpty)
        if let replacement { #expect(replacement.allows(.manageStoreSettings)) }
    }

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

    @Test func test_make_when_launch_lock_is_off_and_previous_session_ended_unlocked_then_resumes_operator() async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        try sut.store.setPIN("1234", for: .admin)
        try sut.store.setPIN("5678", for: .cashier)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: false)
        #expect(first.isLocked)
        try await first.signIn(withPIN: "5678")

        // When
        first.endSession()
        let second = try await makeReplacement(sut, locksWhenPOSOpens: false)

        // Then
        #expect(!second.isLocked)
        #expect(second.currentStaff == POSLocalRole.cashier.staff)
        #expect(!second.allows(.manageStoreSettings))
        #expect(sut.defaultsScope.defaults.bool(forKey: POSLockStateKey.key(for: sut.siteID)) == false)
    }

    @Test func test_make_when_launch_lock_is_on_then_locks_after_unlocked_session() async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        try sut.store.setPIN("1234", for: .admin)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: true)
        try await first.signIn(withPIN: "1234")

        // When
        first.endSession()
        let second = try await makeReplacement(sut, locksWhenPOSOpens: true)

        // Then
        #expect(second.isLocked)
        #expect(second.currentStaff == nil)
    }

    @Test func test_make_when_launch_lock_is_off_and_previous_session_was_locked_then_stays_locked() async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        try sut.store.setPIN("1234", for: .admin)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: false)
        try await first.signIn(withPIN: "1234")
        first.lock()

        // When
        first.endSession()
        let second = try await makeReplacement(sut, locksWhenPOSOpens: false)

        // Then
        #expect(second.isLocked)
        #expect(second.currentStaff == nil)
        #expect(sut.defaultsScope.defaults.bool(forKey: POSLockStateKey.key(for: sut.siteID)))
    }

    @Test func test_make_when_unlocked_staff_was_forgotten_then_locks_without_persisting_lock() async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        try sut.store.setPIN("1234", for: .admin)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: false)
        try await first.signIn(withPIN: "1234")
        first.endSession()

        // When
        POSAccessSessionFactory.forgetUnlockedStaff(siteID: sut.siteID)
        let persistedLockAfterExit = sut.defaultsScope.defaults.bool(forKey: POSLockStateKey.key(for: sut.siteID))
        let second = try await makeReplacement(sut, locksWhenPOSOpens: false)

        // Then
        #expect(!persistedLockAfterExit)
        #expect(second.isLocked)
        #expect(second.currentStaff == nil)
    }

    @Test func test_make_when_launch_lock_is_off_and_operator_pin_was_removed_then_locks() async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        try sut.store.setPIN("1234", for: .admin)
        try sut.store.setPIN("5678", for: .cashier)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: false)
        try await first.signIn(withPIN: "5678")
        first.endSession()

        // When
        try sut.store.removePIN(for: .cashier)
        let second = try await makeReplacement(sut, locksWhenPOSOpens: false)

        // Then
        #expect(second.isLocked)
        #expect(second.currentStaff == nil)
    }

    @Test(arguments: POSInactivityLockTimeout.allCases.filter { $0 != .never })
    func test_make_when_retained_operator_reaches_inactivity_timeout_then_locks(timeout: POSInactivityLockTimeout) async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        let clock = ResumeClock()
        POSLockSettings(siteID: sut.siteID, userDefaults: sut.defaultsScope.defaults).update { $0.inactivityTimeout = timeout }
        try sut.store.setPIN("1234", for: .admin)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: false, now: { clock.current })
        try await first.signIn(withPIN: "1234")
        first.endSession()

        // When
        clock.current += TimeInterval(timeout.rawValue * 60)
        let second = try await makeReplacement(sut, locksWhenPOSOpens: false, now: { clock.current })

        // Then
        #expect(second.isLocked)
        #expect(second.currentStaff == nil)
    }

    @Test func test_make_when_retained_operator_is_within_inactivity_timeout_then_resumes() async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        let clock = ResumeClock()
        try sut.store.setPIN("1234", for: .admin)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: false, now: { clock.current })
        try await first.signIn(withPIN: "1234")
        first.endSession()

        // When
        clock.current += 299
        let second = try await makeReplacement(sut, locksWhenPOSOpens: false, now: { clock.current })

        // Then
        #expect(!second.isLocked)
        #expect(second.currentStaff == POSLocalRole.admin.staff)
    }

    @Test func test_make_when_inactivity_is_never_then_retains_operator_across_idle_gap() async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        let clock = ResumeClock()
        POSLockSettings(siteID: sut.siteID, userDefaults: sut.defaultsScope.defaults).update { $0.inactivityTimeout = .never }
        try sut.store.setPIN("1234", for: .admin)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: false, now: { clock.current })
        try await first.signIn(withPIN: "1234")
        first.endSession()

        // When
        clock.current += 86400
        let second = try await makeReplacement(sut, locksWhenPOSOpens: false, now: { clock.current })

        // Then
        #expect(!second.isLocked)
    }

    @Test(arguments: [true, false])
    func test_make_when_app_backgrounds_outside_pos_then_obeys_background_preference(locksInBackground: Bool) async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        POSLockSettings(siteID: sut.siteID, userDefaults: sut.defaultsScope.defaults).update { $0.locksInBackground = locksInBackground }
        try sut.store.setPIN("1234", for: .admin)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: false)
        try await first.signIn(withPIN: "1234")
        first.endSession()

        // When
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        let second = try await makeReplacement(sut, locksWhenPOSOpens: false)

        // Then
        #expect(second.isLocked == locksInBackground)
        #expect((second.currentStaff == nil) == locksInBackground)
    }

    @Test func test_make_when_session_cleanup_follows_background_notification_then_does_not_retain_operator() async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        try sut.store.setPIN("1234", for: .admin)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: false)
        try await first.signIn(withPIN: "1234")

        // When
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        first.endSession()
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        let second = try await makeReplacement(sut, locksWhenPOSOpens: false)

        // Then
        #expect(second.isLocked)
        #expect(second.currentStaff == nil)
    }

    @Test func test_background_when_store_preferences_change_then_evicts_only_matching_store() async throws {
        // Given
        let firstStore = makeSUT(siteID: uniqueSiteID())
        let secondStore = makeSUT(siteID: uniqueSiteID())
        let firstSettings = POSLockSettings(siteID: firstStore.siteID, userDefaults: firstStore.defaultsScope.defaults)
        firstSettings.update { $0.locksInBackground = false }
        POSLockSettings(siteID: secondStore.siteID, userDefaults: secondStore.defaultsScope.defaults).update { $0.locksInBackground = false }
        try firstStore.store.setPIN("1234", for: .admin)
        try secondStore.store.setPIN("1234", for: .admin)
        let first = try await makeReplacement(firstStore, locksWhenPOSOpens: false)
        let second = try await makeReplacement(secondStore, locksWhenPOSOpens: false)
        try await first.signIn(withPIN: "1234")
        try await second.signIn(withPIN: "1234")
        first.endSession()
        second.endSession()

        // When
        firstSettings.update { $0.locksInBackground = true }
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        let reopenedFirst = try await makeReplacement(firstStore, locksWhenPOSOpens: false)
        let reopenedSecond = try await makeReplacement(secondStore, locksWhenPOSOpens: false)

        // Then
        #expect(reopenedFirst.isLocked)
        #expect(!reopenedSecond.isLocked)
    }

    @Test func test_make_when_clock_moves_backwards_then_does_not_extend_retained_operator() async throws {
        // Given
        let sut = makeSUT(siteID: uniqueSiteID())
        let clock = ResumeClock()
        try sut.store.setPIN("1234", for: .admin)
        let first = try await makeReplacement(sut, locksWhenPOSOpens: false, now: { clock.current })
        try await first.signIn(withPIN: "1234")
        first.endSession()

        // When
        clock.current -= 1
        let second = try await makeReplacement(sut, locksWhenPOSOpens: false, now: { clock.current })

        // Then
        #expect(second.isLocked)
    }

    @Test(arguments: PendingPINChange.allCases)
    func test_make_when_pin_mutation_is_pending_then_waits_for_committed_protection(change: PendingPINChange) async throws {
        // Given
        let sut = makeSUT(fails: change.fails)
        if change == .removal {
            try sut.store.setPIN("1234", for: .admin)
            try sut.session.refreshPINProtection()
            try await sut.session.signIn(withPIN: "1234")
        }
        sut.controller.load()
        let save = Task { await changePIN(using: sut, removing: change == .removal) }
        defer { sut.blocking.releaseMutation() }
        try await sut.blocking.waitUntilEntered()
        #expect(!sut.limiter.pendingPINChanges.isEmpty)
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

        // Then
        #expect(constructed == false)
        let unrelatedStore = makeSUT(siteID: 124)
        #expect(try await makeReplacement(unrelatedStore).isPINProtectionEnabled == false)
        sut.blocking.releaseMutation()
        #expect(await save.value == !change.fails)
        let current = try await replacement.value
        #expect(current.isPINProtectionEnabled == change.leavesProtection)
        #expect(current.isLocked == change.leavesProtection)
        #expect(sut.limiter.pendingPINChanges.isEmpty)
    }

    @Test func test_cancellation_when_worker_is_pending_then_neither_publishes_owner_nor_releases_mutation_early() async throws {
        // Given
        let sut = makeSUT()
        sut.controller.load()
        let save = Task { await changePIN(using: sut) }
        defer { sut.blocking.releaseMutation() }
        try await sut.blocking.waitUntilEntered()
        let token = sut.limiter.sessionTokens.current()
        let marker = sut.defaultsScope.defaults.object(forKey: POSLockStateKey.key(for: 123)) as? Bool
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
        #expect(!sut.limiter.pendingPINChanges.isEmpty)
        #expect(sut.limiter.sessionTokens.isCurrent(token))
        #expect(sut.defaultsScope.defaults.object(forKey: POSLockStateKey.key(for: 123)) as? Bool == marker)
        sut.blocking.releaseMutation()
        #expect(await save.value == false)
        #expect(sut.limiter.pendingPINChanges.isEmpty)
        #expect(try sut.store.configuredRoles().isEmpty)
        #expect(sut.session.currentStaff == nil)
    }

    @Test func test_make_when_already_cancelled_then_does_not_claim_owner_or_write_marker() async {
        // Given
        let sut = makeSUT()
        let token = sut.limiter.sessionTokens.current()
        let marker = sut.defaultsScope.defaults.object(forKey: POSLockStateKey.key(for: 123)) as? Bool
        let task = Task { try await makeReplacement(sut) }
        task.cancel()

        // When / Then
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(sut.limiter.sessionTokens.isCurrent(token))
        #expect(sut.defaultsScope.defaults.object(forKey: POSLockStateKey.key(for: 123)) as? Bool == marker)
    }

    @Test func test_two_entrants_when_pending_change_finishes_then_only_needed_entry_can_claim_owner() async throws {
        // Given
        let sut = makeSUT()
        sut.controller.load()
        let save = Task { await changePIN(using: sut) }
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

extension POSAccessSessionFactoryTests {
    enum PendingPINChange: CaseIterable {
        case setup
        case removal
        case failure

        var fails: Bool {
            switch self {
            case .setup, .removal: false
            case .failure: true
            }
        }

        var leavesProtection: Bool {
            switch self {
            case .setup: true
            case .removal, .failure: false
            }
        }
    }
}

private extension POSAccessSessionFactoryTests {
    func changePIN(using sut: SUT, removing: Bool = false) async -> Bool {
        if removing {
            let handler = POSManagerOverrideHandler(session: sut.session)
            let request = Task { await sut.controller.requestProtectionRemoval(using: handler, reason: "Remove protection") }
            await withCheckedContinuation { ready in
                withObservationTracking { _ = handler.request } onChange: {
                    Task { @MainActor in ready.resume() }
                }
            }
            _ = await handler.submit(pin: "1234")
            return await request.value == .completed
        }
        let setup = sut.controller.makePINSetupController(for: .admin)
        guard await setup.submit("1234") == .confirmationRequired else { return false }
        return await setup.submit("1234") == .saved
    }

    struct SUT {
        let siteID: Int64
        let store: POSLocalPINStore
        let blocking: MockBlockingPOSPINStore
        let limiter: POSLocalRateLimiter
        let session: DefaultPOSAccessSession
        let controller: POSSecuritySettingsController
        let defaultsScope: FactoryTestDefaults
    }

    func makeSUT(fails: Bool = false, siteID: Int64 = 123, blocksValidation: Bool = false) -> SUT {
        let store = POSLocalPINStore(siteID: siteID, storage: InMemoryPOSSecureStorage(), iterations: 1)
        let blocking = MockBlockingPOSPINStore(store: store, fails: fails, blocksValidation: blocksValidation)
        let limiter = POSLocalRateLimiter(siteID: siteID, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock())
        let defaultsScope = FactoryTestDefaults()
        let session = DefaultPOSAccessSession(siteID: siteID, authenticator: DefaultPOSPINAuthenticator(credentialProvider: store),
                                              rateLimiter: limiter, credentialProvider: store, userDefaults: defaultsScope.defaults)
        return SUT(siteID: siteID, store: store, blocking: blocking, limiter: limiter, session: session,
                   controller: POSSecuritySettingsController(store: blocking, session: session,
                                                             lockSettings: POSLockSettings(siteID: siteID, userDefaults: defaultsScope.defaults)),
                   defaultsScope: defaultsScope)
    }

    func makeReplacement(_ sut: SUT,
                         locksWhenPOSOpens: Bool = true,
                         now: @escaping @MainActor () -> Date = Date.init,
                         shouldCreate: @MainActor () -> Bool = { true }) async throws -> POSAccessSession {
        try await POSAccessSessionFactory.make(siteID: sut.siteID, featureFlags: StubPOSFeatureFlagProviding(enabledFlags: [.pointOfSaleRoles]),
                                               credentialProvider: sut.store, rateLimiter: sut.limiter, userDefaults: sut.defaultsScope.defaults,
                                               locksWhenPOSOpens: locksWhenPOSOpens, now: now, shouldCreate: shouldCreate)
    }

    /// The factory keeps unlocked operators per store in memory, so each launch-lock test uses its own store.
    func uniqueSiteID() -> Int64 {
        Int64.random(in: 1_000_000...Int64.max)
    }
}

private final class FactoryTestDefaults {
    let defaults: UserDefaults
    private let name = "POSFactoryTests." + UUID().uuidString
    init() { defaults = UserDefaults(suiteName: name) ?? .standard }
    deinit { defaults.removePersistentDomain(forName: name) }
}

private final class StubPOSFeatureFlagProviding: POSFeatureFlagProviding {
    let enabledFlags: Set<FeatureFlag>

    init(enabledFlags: Set<FeatureFlag>) {
        self.enabledFlags = enabledFlags
    }

    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool {
        enabledFlags.contains(flag)
    }
}

@MainActor
private final class ResumeClock {
    var current = Date(timeIntervalSinceReferenceDate: 0)
}
