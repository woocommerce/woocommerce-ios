import Foundation
import Observation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSPINSetupFlowTests {
    private let storage = InMemoryPOSSecureStorage()
    private let defaultsScope = POSPINSetupFlowTestDefaults()
    private let sleeper = MockSleeper()

    @Test(arguments: [(.initialAdmin, false), (.adminChange, true), (.cashier, true)] as [(POSPINSetupFlow.Configuration, Bool)])
    func test_continue_when_saved_then_only_initial_admin_setup_offers_guided_access(configuration: POSPINSetupFlow.Configuration, closes: Bool) async {
        // Given
        var saves = 0
        let setup = POSPINSetupController(validatePIN: { _ in }, savePIN: { _ in saves += 1; return true })
        let sut = POSPINSetupFlow(configuration: configuration, setup: setup, sleep: { _ in })
        #expect(await sut.submit("1234"))
        #expect(await sut.submit("1234"))

        // When
        let shouldClose = sut.continueFromSuccess()

        // Then
        #expect(saves == 1)
        #expect(shouldClose == closes)
        #expect(sut.step == (closes ? .saved : .guidedAccessOffer))
    }

    @Test func test_continue_when_not_saved_then_does_not_close_or_offer_guided_access() {
        // Given
        let sut = POSPINSetupFlow(configuration: .initialAdmin, setup: POSPINSetupController(validatePIN: { _ in }, savePIN: { _ in true }))

        // When / Then
        #expect(!sut.continueFromSuccess())
        #expect(sut.step == .choose)
    }

    @Test(arguments: [POSPINStoreError.storageFailure, .pinMatchesOtherRole])
    func test_confirm_when_save_rejects_then_shows_specific_failure_without_success(error: POSPINStoreError) async {
        // Given
        let setup = POSPINSetupController(validatePIN: { _ in }, savePIN: { _ throws(POSPINStoreError) in throw error })
        let sut = POSPINSetupFlow(configuration: .cashier, setup: setup, sleep: { _ in })
        #expect(await sut.submit("1234"))

        // When
        let accepted = await sut.submit("1234")

        // Then
        #expect(!accepted)
        #expect(sut.step == .choose)
        #expect(sut.feedback == .failure(error))
        #expect(!sut.continueFromSuccess())
    }

    @Test(arguments: [POSPINStoreError.pinMatchesOtherRole, .storageFailure])
    func test_choose_when_validation_rejects_then_waits_for_shake_before_showing_feedback(error: POSPINStoreError) async throws {
        // Given
        let setup = POSPINSetupController(validatePIN: { _ in throw error }, savePIN: { _ in true })
        let sut = POSPINSetupFlow(configuration: .cashier, setup: setup, sleep: sleeper.sleep)
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        let submission = Task { await sut.submit("1234") }
        try await expectSleep(.milliseconds(500), from: &sleeps)

        // When
        sleeper.resumeNext()
        #expect(await submission.value == false)

        // Then
        try #require(sut.feedback == nil)
        #expect(sut.pinEntryState == .loading)
        try await expectSleep(.milliseconds(550), from: &sleeps)
        sleeper.resumeNext()
        await waitUntil { sut.feedback == .failure(error) }
        #expect(sut.pinEntryState == .idle)
        #expect(sut.step == .choose)
        #expect(sut.pageID == 0)
        #expect(sleeper.durations == [.milliseconds(500), .milliseconds(550)])
    }

    @Test func test_close_when_validating_then_keeps_flow_open_and_rejects_reentry() async {
        // Given
        weak var flow: POSPINSetupFlow?
        let setup = POSPINSetupController(validatePIN: { _ in
            let current = try #require(flow)
            #expect(!current.canClose)
            #expect(!current.close())
            #expect(await current.submit("5678") == false)
        }, savePIN: { _ in Issue.record("Validation must not save"); return false })
        let sut = POSPINSetupFlow(configuration: .initialAdmin, setup: setup, sleep: { _ in })
        flow = sut

        // When
        let accepted = await sut.submit("1234")

        // Then
        #expect(accepted)
        #expect(sut.step == .confirm)
        #expect(sut.canClose)
    }

    @Test func test_choose_when_four_digits_are_entered_then_holds_filled_dots_before_confirm() async throws {
        // Given
        let (sut, controller, _) = makeSUT()
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()

        // When
        let submission = Task { await sut.submit("1234") }
        try await expectSleep(.milliseconds(500), from: &sleeps)

        // Then
        #expect(sut.step == .choose)
        #expect(sut.pinEntryState == .loading)
        #expect(await sut.submit("5678") == false)
        sleeper.resumeNext()
        #expect(await submission.value)
        #expect(sut.step == .confirm)
        #expect(sut.pageID == 1)
        #expect(sut.pinEntryState == .idle)
        #expect(sut.canGoBack)
        #expect(controller.roles == [])
    }

    @Test func test_confirm_when_pin_matches_then_saves_once_and_shows_success_after_loading() async throws {
        // Given
        let (sut, controller, session) = makeSUT()
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)

        // When
        let submission = Task { await sut.submit("1234") }
        try await expectSleep(.milliseconds(500), from: &sleeps)

        // Then
        #expect(sut.step == .confirm)
        #expect(!sut.canGoBack)
        sleeper.resumeNext()
        try await expectSleep(.seconds(1), from: &sleeps)
        #expect(sut.step == .saving)
        sleeper.resumeNext()
        #expect(await submission.value)
        #expect(sut.step == .saved)
        #expect(controller.roles == [.admin])
        #expect(session.isPINProtectionEnabled)
        #expect(session.currentStaff == POSLocalRole.admin.staff)
        #expect(!session.isLocked)
        #expect(sleeper.durations == [.milliseconds(500), .milliseconds(500), .seconds(1)])
    }

    @Test func test_confirm_when_presentation_is_pending_then_saves_immediately_and_rejects_duplicate_submission() async throws {
        // Given
        var saveCount = 0
        let setup = POSPINSetupController(validatePIN: { _ in }, savePIN: { _ in
            saveCount += 1
            return true
        })
        let sut = POSPINSetupFlow(configuration: .initialAdmin, setup: setup, sleep: sleeper.sleep)
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)

        // When
        let submission = Task { await sut.submit("1234") }
        try await expectSleep(.milliseconds(500), from: &sleeps)

        // Then
        #expect(saveCount == 1)
        #expect(await sut.submit("1234") == false)
        #expect(saveCount == 1)
        sleeper.resumeNext()
        try await expectSleep(.seconds(1), from: &sleeps)
        sleeper.resumeNext()
        #expect(await submission.value)
    }

    @Test func test_close_when_saved_result_is_held_then_ignores_late_success_without_repeating_save() async throws {
        // Given
        var saveCount = 0
        let setup = POSPINSetupController(validatePIN: { _ in }, savePIN: { _ in
            saveCount += 1
            return true
        })
        let sut = POSPINSetupFlow(configuration: .initialAdmin, setup: setup, sleep: sleeper.sleep)
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)
        let submission = Task { await sut.submit("1234") }
        try await expectSleep(.milliseconds(500), from: &sleeps)

        // When
        await waitUntil { sut.canClose }
        #expect(sut.close())
        sleeper.resumeNext()

        // Then
        #expect(await submission.value == false)
        #expect(saveCount == 1)
        #expect(sut.step != .saved)
    }

    @Test func test_confirm_when_saving_is_slower_than_loading_then_success_waits_for_save() async throws {
        // Given
        var finishSave: CheckedContinuation<Bool, Never>?
        let setup = POSPINSetupController(validatePIN: { _ in }, savePIN: { _ in
            await withCheckedContinuation { finishSave = $0 }
        })
        let sut = POSPINSetupFlow(configuration: .initialAdmin, setup: setup, sleep: sleeper.sleep)
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)

        // When
        let submission = Task { await sut.submit("1234") }
        try await expectSleep(.milliseconds(500), from: &sleeps)
        sleeper.resumeNext()
        try await expectSleep(.seconds(1), from: &sleeps)
        sleeper.resumeNext()

        // Then
        #expect(sut.step == .saving)
        #expect(!sut.close())
        try #require(finishSave).resume(returning: true)
        #expect(await submission.value)
        #expect(sut.step == .saved)
    }

    @Test func test_confirm_when_save_fails_then_returns_to_choose_with_failure_and_no_success() async throws {
        // Given
        let (sut, controller, session) = makeSUT()
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)
        storage.shouldFail = true

        // When
        let submission = Task { await sut.submit("1234") }
        try await expectSleep(.milliseconds(500), from: &sleeps)
        sleeper.resumeNext()
        try await expectSleep(.seconds(1), from: &sleeps)
        sleeper.resumeNext()

        // Then
        #expect(await submission.value == false)
        #expect(sut.step == .choose)
        #expect(sut.feedback == .failure(.storageFailure))
        #expect(sut.pageID == 2)
        #expect(storage.values.isEmpty)
        #expect(controller.roles == nil)
        #expect(session.currentStaff == nil)
    }

    @Test func test_confirm_when_pin_differs_then_shakes_returns_to_choose_and_explains_mismatch() async throws {
        // Given
        let (sut, _, _) = makeSUT()
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)

        // When
        let accepted = await sut.submit("5678")

        // Then
        #expect(!accepted)
        #expect(sut.step == .confirm)
        #expect(sut.pinEntryState == .loading)
        try await expectSleep(.milliseconds(550), from: &sleeps)
        sleeper.resumeNext()
        try await expectSleep(.milliseconds(500), from: &sleeps)
        #expect(sut.step == .choose)
        #expect(sut.pageID == 2)
        #expect(sut.feedback == nil)
        #expect(sut.pinEntryState == .idle)
        sleeper.resumeNext()
        await waitUntil { sut.feedback == .mismatch }
        #expect(storage.values.isEmpty)
    }

    @Test func test_choose_after_mismatch_when_new_pin_is_entered_then_clears_mismatch_and_needs_confirmation() async throws {
        // Given
        let (sut, controller, _) = makeSUT()
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)
        _ = await sut.submit("5678")
        try await expectSleep(.milliseconds(550), from: &sleeps)
        sleeper.resumeNext()
        try await expectSleep(.milliseconds(500), from: &sleeps)
        sleeper.resumeNext()
        await waitUntil { sut.feedback == .mismatch }

        // When
        let submission = Task { await sut.submit("5678") }
        try await expectSleep(.milliseconds(500), from: &sleeps)
        sleeper.resumeNext()

        // Then
        #expect(await submission.value)
        #expect(sut.feedback == nil)
        #expect(sut.step == .confirm)
        #expect(controller.roles == [])
    }

    @Test func test_goBack_when_confirming_then_discards_first_pin_and_returns_to_choose() async throws {
        // Given
        let (sut, controller, _) = makeSUT()
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)

        // When
        sut.goBack()

        // Then
        #expect(sut.step == .choose)
        #expect(sut.pageID == 2)
        #expect(!sut.canGoBack)
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)
        #expect(sut.step == .confirm)
        #expect(controller.roles == [])
    }

    @Test func test_close_when_first_pin_is_held_then_late_result_does_not_advance() async throws {
        // Given
        let (sut, _, _) = makeSUT()
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        let submission = Task { await sut.submit("1234") }
        try await expectSleep(.milliseconds(500), from: &sleeps)
        await waitUntil { sut.canClose }

        // When
        let closed = sut.close()
        sleeper.resumeNext()

        // Then
        #expect(closed)
        #expect(await submission.value == false)
        #expect(sut.step == .choose)
        #expect(sut.pageID == 0)
    }

    @Test func test_discard_when_mismatch_is_pending_then_does_not_change_flow() async throws {
        // Given
        let (sut, _, _) = makeSUT()
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)
        _ = await sut.submit("5678")
        try await expectSleep(.milliseconds(550), from: &sleeps)

        // When
        sut.discard()
        sleeper.resumeNext()
        await Task.yield()

        // Then
        #expect(sut.step == .confirm)
        #expect(sut.feedback == nil)
        #expect(sleeper.durations.count == 2)
    }

    @Test func test_guided_access_offer_when_closed_then_keeps_saved_pin() async throws {
        // Given
        let (sut, controller, session) = makeSUT()
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)
        let submission = Task { await sut.submit("1234") }
        try await expectSleep(.milliseconds(500), from: &sleeps)
        sleeper.resumeNext()
        try await expectSleep(.seconds(1), from: &sleeps)
        sleeper.resumeNext()
        _ = await submission.value

        // When
        _ = sut.continueFromSuccess()
        let closed = sut.close()

        // Then
        #expect(sut.step == .guidedAccessOffer)
        #expect(closed)
        #expect(controller.roles == [.admin])
        #expect(session.isPINProtectionEnabled)
    }
}

private extension POSPINSetupFlowTests {
    func makeSUT() -> (POSPINSetupFlow, POSSecuritySettingsController, DefaultPOSAccessSession) {
        let store = POSLocalPINStore(siteID: 123, storage: storage, iterations: 1)
        let session = DefaultPOSAccessSession(siteID: 123,
                                             authenticator: DefaultPOSPINAuthenticator(credentialProvider: store),
                                             rateLimiter: POSLocalRateLimiter(siteID: 123, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock()),
                                             credentialProvider: store,
                                             userDefaults: defaultsScope.defaults)
        let controller = POSSecuritySettingsController(store: store, session: session,
                                                       lockSettings: POSLockSettings(siteID: 123, userDefaults: defaultsScope.defaults),
                                                       flowSleep: sleeper.sleep)
        controller.load()
        return (controller.makePINSetupFlow(for: .admin), controller, session)
    }

    func enterFirstPIN(_ pin: String, sut: POSPINSetupFlow, sleeps: inout AsyncStream<Duration>.Iterator) async throws {
        let submission = Task { await sut.submit(pin) }
        try await expectSleep(.milliseconds(500), from: &sleeps)
        sleeper.resumeNext()
        try #require(await submission.value)
    }

    func expectSleep(_ duration: Duration, from iterator: inout AsyncStream<Duration>.Iterator) async throws {
        let next = await iterator.next(isolation: MainActor.shared)
        let actual = try #require(next)
        try #require(actual == duration)
    }

    /// Checking and observing both run on the main actor, so no change is missed in between.
    func waitUntil(_ condition: @escaping @MainActor () -> Bool) async {
        while !condition() {
            await withCheckedContinuation { continuation in
                withObservationTracking {
                    _ = condition()
                } onChange: {
                    Task { @MainActor in continuation.resume() }
                }
            }
        }
    }
}

private final class POSPINSetupFlowTestDefaults {
    let defaults: UserDefaults
    private let name = "POSPINSetupFlowTests.\(UUID().uuidString)"
    init() { defaults = UserDefaults(suiteName: name)! }
    deinit { defaults.removePersistentDomain(forName: name) }
}
