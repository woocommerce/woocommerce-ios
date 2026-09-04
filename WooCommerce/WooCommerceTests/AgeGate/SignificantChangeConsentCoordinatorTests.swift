import XCTest
@testable import WooCommerce

final class SignificantChangeConsentCoordinatorTests: XCTestCase {
    private let ratingChange = AgeRatingChangeCheckResult.ageRatingChanged(previous: 4, current: 13)
    private let ratingChangeIdentifier = SignificantChangeIdentifier.ageRatingChange(ratingCode: 13)

    // MARK: - checkConsentIfNeeded (read-only)

    @MainActor func test_checkConsentIfNeeded_when_no_change_then_returns_notRequired() {
        // Given
        let provider = MockConsentProvider(requestResult: .sent(questionID: UUID()))
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = sut.checkConsentIfNeeded(ageRatingChange: nil)

        // Then
        XCTAssertEqual(state, .notRequired)
        XCTAssertEqual(provider.requestCount, 0)
    }

    @MainActor func test_checkConsentIfNeeded_when_no_status_then_returns_required_without_sending_request() {
        // Given
        let provider = MockConsentProvider(requestResult: .sent(questionID: UUID()))
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = sut.checkConsentIfNeeded(ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .required)
        XCTAssertEqual(provider.requestCount, 0)
        XCTAssertEqual(store.setCount, 0)
    }

    @MainActor func test_checkConsentIfNeeded_when_cached_granted_then_returns_granted() {
        // Given
        let store = MockConsentStore()
        store.statusByIdentifier[ratingChangeIdentifier] = .granted
        let sut = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(requestResult: .notAvailable),
            consentStore: store
        )

        // When
        let state = sut.checkConsentIfNeeded(ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .granted)
    }

    @MainActor func test_checkConsentIfNeeded_when_cached_denied_then_returns_denied() {
        // Given
        let store = MockConsentStore()
        store.statusByIdentifier[ratingChangeIdentifier] = .denied
        let sut = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(requestResult: .notAvailable),
            consentStore: store
        )

        // When
        let state = sut.checkConsentIfNeeded(ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .denied)
    }

    @MainActor func test_checkConsentIfNeeded_when_cached_pending_then_returns_pending() {
        // Given
        let store = MockConsentStore()
        store.statusByIdentifier[ratingChangeIdentifier] = .pending
        let sut = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(requestResult: .notAvailable),
            consentStore: store
        )

        // When
        let state = sut.checkConsentIfNeeded(ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .pending)
    }

    // MARK: - requestConsent (explicit user action)

    @MainActor func test_requestConsent_when_question_sent_then_persists_pending_and_returns_pending() async {
        // Given
        let questionID = UUID()
        let provider = MockConsentProvider(requestResult: .sent(questionID: questionID))
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.requestConsent(in: UIViewController(), ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .pending)
        XCTAssertEqual(provider.requestCount, 1)
        XCTAssertEqual(store.statusByIdentifier[ratingChangeIdentifier], .pending)
        XCTAssertEqual(
            store.pendingRequest,
            PendingConsentRequest(questionID: questionID, identifier: ratingChangeIdentifier)
        )
    }

    @MainActor func test_requestConsent_when_approval_arrives_within_grace_window_then_returns_granted_directly() async {
        // Given
        let questionID = UUID()
        let provider = MockConsentProvider(requestResult: .sent(questionID: questionID))
        provider.stubbedResponses = [.init(questionID: questionID, isApproved: true)]
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.requestConsent(in: UIViewController(), ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .granted)
        XCTAssertEqual(store.statusByIdentifier[ratingChangeIdentifier], .granted)
        XCTAssertNil(store.pendingRequest)
    }

    @MainActor func test_requestConsent_when_denial_arrives_within_grace_window_then_returns_denied_directly() async {
        // Given
        let questionID = UUID()
        let provider = MockConsentProvider(requestResult: .sent(questionID: questionID))
        provider.stubbedResponses = [.init(questionID: questionID, isApproved: false)]
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.requestConsent(in: UIViewController(), ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .denied)
        XCTAssertEqual(store.statusByIdentifier[ratingChangeIdentifier], .denied)
        XCTAssertNil(store.pendingRequest)
    }

    @MainActor func test_requestConsent_when_answer_arrives_while_send_is_in_flight_then_returns_final_state() async {
        // Given
        let questionID = UUID()
        let provider = MockConsentProvider(requestResult: .sent(questionID: questionID))
        provider.finishesStreamImmediately = false
        // The system answers before `ask` returns — the coordinator doesn't know the question id yet.
        provider.responsesDeliveredDuringRequest = [.init(questionID: questionID, isApproved: true)]
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.requestConsent(in: UIViewController(), ageRatingChange: ratingChange)

        // Then
        // A dropped answer would leave the request pending after the grace window instead.
        XCTAssertEqual(state, .granted)
        XCTAssertEqual(store.statusByIdentifier[ratingChangeIdentifier], .granted)
        XCTAssertNil(store.pendingRequest)
    }

    @MainActor func test_requestConsent_when_grace_window_response_is_for_other_question_then_stays_pending() async {
        // Given
        let provider = MockConsentProvider(requestResult: .sent(questionID: UUID()))
        provider.stubbedResponses = [.init(questionID: UUID(), isApproved: true)]
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.requestConsent(in: UIViewController(), ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .pending)
        XCTAssertEqual(store.statusByIdentifier[ratingChangeIdentifier], .pending)
        XCTAssertNotNil(store.pendingRequest)
    }

    @MainActor func test_requestConsent_when_notAvailable_then_returns_notAvailable_and_stores_nothing() async {
        // Given
        let provider = MockConsentProvider(requestResult: .notAvailable)
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.requestConsent(in: UIViewController(), ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .notAvailable)
        XCTAssertEqual(store.setCount, 0)
        XCTAssertNil(store.pendingRequest)
    }

    @MainActor func test_requestConsent_when_previously_denied_then_asks_again_and_marks_pending() async {
        // Given
        let questionID = UUID()
        let provider = MockConsentProvider(requestResult: .sent(questionID: questionID))
        let store = MockConsentStore()
        store.statusByIdentifier[ratingChangeIdentifier] = .denied
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.requestConsent(in: UIViewController(), ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .pending)
        XCTAssertEqual(provider.requestCount, 1)
        XCTAssertEqual(store.statusByIdentifier[ratingChangeIdentifier], .pending)
    }

    @MainActor func test_requestConsent_when_previously_denied_and_re_ask_fails_then_keeps_denial() async {
        // Given
        let provider = MockConsentProvider(requestResult: .failed)
        let store = MockConsentStore()
        store.statusByIdentifier[ratingChangeIdentifier] = .denied
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.requestConsent(in: UIViewController(), ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .notAvailable)
        XCTAssertEqual(provider.requestCount, 1)
        // A failed re-ask must not downgrade "declined" to "never asked".
        XCTAssertEqual(store.statusByIdentifier[ratingChangeIdentifier], .denied)
        XCTAssertNil(store.pendingRequest)
    }

    @MainActor func test_requestConsent_when_already_granted_then_returns_granted_without_asking() async {
        // Given
        let provider = MockConsentProvider(requestResult: .sent(questionID: UUID()))
        let store = MockConsentStore()
        store.statusByIdentifier[ratingChangeIdentifier] = .granted
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.requestConsent(in: UIViewController(), ageRatingChange: ratingChange)

        // Then
        XCTAssertEqual(state, .granted)
        XCTAssertEqual(provider.requestCount, 0)
    }

    @MainActor func test_requestConsent_when_manual_identifier_then_takes_precedence_and_persists_pending() async {
        // Given
        let questionID = UUID()
        let manualIdentifier = SignificantChangeIdentifier.manual(id: "new-feature")
        let provider = MockConsentProvider(requestResult: .sent(questionID: questionID))
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.requestConsent(
            in: UIViewController(),
            ageRatingChange: ratingChange,
            manualChangeIdentifier: manualIdentifier
        )

        // Then
        XCTAssertEqual(state, .pending)
        XCTAssertEqual(store.statusByIdentifier[manualIdentifier], .pending)
        XCTAssertNil(store.statusByIdentifier[ratingChangeIdentifier])
        XCTAssertEqual(
            store.pendingRequest,
            PendingConsentRequest(questionID: questionID, identifier: manualIdentifier)
        )
    }

    // MARK: - Response listener

    @MainActor func test_startObservingResponses_when_pending_question_approved_then_stores_granted_and_notifies() async {
        // Given
        let questionID = UUID()
        let provider = MockConsentProvider(requestResult: .sent(questionID: questionID))
        provider.stubbedResponses = [.init(questionID: questionID, isApproved: true)]
        let store = MockConsentStore()
        store.statusByIdentifier[ratingChangeIdentifier] = .pending
        store.pendingRequest = PendingConsentRequest(questionID: questionID, identifier: ratingChangeIdentifier)
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)
        let exp = expectation(description: "onResolution")

        // When
        var resolvedStatus: SignificantChangeConsentStatus?
        sut.startObservingResponses { status in
            resolvedStatus = status
            exp.fulfill()
        }

        // Then
        await fulfillment(of: [exp], timeout: 1)
        XCTAssertEqual(resolvedStatus, .granted)
        XCTAssertEqual(store.statusByIdentifier[ratingChangeIdentifier], .granted)
        XCTAssertNil(store.pendingRequest)
    }

    @MainActor func test_startObservingResponses_when_response_for_unknown_question_then_ignores_it() async {
        // Given
        let provider = MockConsentProvider(requestResult: .notAvailable)
        provider.stubbedResponses = [.init(questionID: UUID(), isApproved: false)]
        let store = MockConsentStore()
        store.pendingRequest = PendingConsentRequest(questionID: UUID(), identifier: ratingChangeIdentifier)
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)
        let exp = expectation(description: "onResolution")
        exp.isInverted = true

        // When
        sut.startObservingResponses { _ in
            exp.fulfill()
        }

        // Then
        await fulfillment(of: [exp], timeout: 0.3)
        XCTAssertNotNil(store.pendingRequest)
        XCTAssertEqual(store.setCount, 0)
    }
}

private final class MockConsentProvider: SignificantChangeConsentProviding {
    let requestResult: SignificantChangeConsentRequestResult
    /// Delivered as soon as the coordinator subscribes to `responses()`.
    var stubbedResponses: [SignificantChangeConsentResponse] = []
    /// Delivered while `requestConsent` is still in flight — before the caller knows the question id.
    var responsesDeliveredDuringRequest: [SignificantChangeConsentResponse] = []
    /// Ends the stream right after the stubbed responses, like a provider that can't deliver more.
    var finishesStreamImmediately = true
    private(set) var requestCount = 0
    private let stream: AsyncStream<SignificantChangeConsentResponse>
    private let continuation: AsyncStream<SignificantChangeConsentResponse>.Continuation

    init(requestResult: SignificantChangeConsentRequestResult) {
        self.requestResult = requestResult
        (stream, continuation) = AsyncStream.makeStream()
    }

    func requestConsent(
        in viewController: UIViewController,
        significantAppUpdateDescription: String
    ) async -> SignificantChangeConsentRequestResult {
        requestCount += 1
        if responsesDeliveredDuringRequest.isEmpty == false {
            responsesDeliveredDuringRequest.forEach { continuation.yield($0) }
            // Stay in flight long enough for the listener to consume the answer, like a real
            // system answer landing before `ask` returns.
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return requestResult
    }

    func responses() -> AsyncStream<SignificantChangeConsentResponse> {
        stubbedResponses.forEach { continuation.yield($0) }
        if finishesStreamImmediately {
            continuation.finish()
        }
        return stream
    }
}

private final class MockConsentStore: SignificantChangeConsentStoring {
    var statusByIdentifier: [SignificantChangeIdentifier: SignificantChangeConsentStatus] = [:]
    var pendingRequest: PendingConsentRequest?
    private(set) var setCount = 0

    func status(for identifier: SignificantChangeIdentifier) -> SignificantChangeConsentStatus? {
        statusByIdentifier[identifier]
    }

    func setStatus(_ status: SignificantChangeConsentStatus, for identifier: SignificantChangeIdentifier) {
        setCount += 1
        statusByIdentifier[identifier] = status
    }

    func setPendingRequest(_ request: PendingConsentRequest) {
        pendingRequest = request
    }

    func clearPendingRequest() {
        pendingRequest = nil
    }
}
