import Foundation
import Observation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSAdminPINOnboardingTests {
    private let storage = InMemoryPOSSecureStorage()
    private let defaultsScope = POSAdminPINOnboardingTestDefaults()
    private let sleeper = MockSleeper()

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
        let sut = POSAdminPINOnboarding(setup: setup, sleep: sleeper.sleep)
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
        let sut = POSAdminPINOnboarding(setup: setup, sleep: sleeper.sleep)
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)
        let submission = Task { await sut.submit("1234") }
        try await expectSleep(.milliseconds(500), from: &sleeps)

        // When
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
        let sut = POSAdminPINOnboarding(setup: setup, sleep: sleeper.sleep)
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

    @Test(arguments: [false, true])
    func test_choose_after_mismatch_when_new_pin_is_entered_then_clears_mismatch_and_needs_confirmation(discardDraft: Bool) async throws {
        // Given
        let (sut, controller, _) = makeSUT()
        defer { sleeper.finish() }
        var sleeps = sleeper.calls.makeAsyncIterator()
        try await enterFirstPIN("1234", sut: sut, sleeps: &sleeps)
        if discardDraft {
            sut.discard()
        }
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
        sut.continueToGuidedAccessOffer()
        let closed = sut.close()

        // Then
        #expect(sut.step == .guidedAccessOffer)
        #expect(closed)
        #expect(controller.roles == [.admin])
        #expect(session.isPINProtectionEnabled)
    }
}

private extension POSAdminPINOnboardingTests {
    func makeSUT() -> (POSAdminPINOnboarding, POSSecuritySettingsController, DefaultPOSAccessSession) {
        let store = POSLocalPINStore(siteID: 123, storage: storage, iterations: 1)
        let session = DefaultPOSAccessSession(siteID: 123,
                                             authenticator: DefaultPOSPINAuthenticator(credentialProvider: store),
                                             rateLimiter: POSLocalRateLimiter(siteID: 123, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock()),
                                             credentialProvider: store,
                                             userDefaults: defaultsScope.defaults)
        let controller = POSSecuritySettingsController(store: store, session: session)
        controller.load()
        return (POSAdminPINOnboarding(setup: controller.makePINSetupController(for: .admin), sleep: sleeper.sleep), controller, session)
    }

    func enterFirstPIN(_ pin: String, sut: POSAdminPINOnboarding, sleeps: inout AsyncStream<Duration>.Iterator) async throws {
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

private final class POSAdminPINOnboardingTestDefaults {
    let defaults: UserDefaults
    private let name = "POSAdminPINOnboardingTests.\(UUID().uuidString)"
    init() { defaults = UserDefaults(suiteName: name)! }
    deinit { defaults.removePersistentDomain(forName: name) }
}
