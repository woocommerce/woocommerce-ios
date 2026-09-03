import XCTest
@testable import WooCommerce

final class SignificantChangeConsentCoordinatorTests: XCTestCase {

    @MainActor func test_checkConsentIfNeeded_when_no_change_then_returns_notRequired() async {
        // Given
        let provider = MockConsentProvider(requestResult: .sent(questionID: UUID()))
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: nil
        )

        // Then
        XCTAssertEqual(state, .notRequired)
        XCTAssertEqual(provider.requestCount, 0)
        XCTAssertEqual(store.setCount, 0)
    }

    @MainActor func test_checkConsentIfNeeded_when_cached_granted_then_returns_granted_without_request() async {
        // Given
        let provider = MockConsentProvider(requestResult: .sent(questionID: UUID()))
        let store = MockConsentStore()
        store.statusByKey["ageRatingChange.13"] = .granted
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: 4, current: 13)
        )

        // Then
        XCTAssertEqual(state, .granted)
        XCTAssertEqual(provider.requestCount, 0)
    }

    @MainActor func test_checkConsentIfNeeded_when_cached_denied_then_returns_denied_without_request() async {
        // Given
        let provider = MockConsentProvider(requestResult: .sent(questionID: UUID()))
        let store = MockConsentStore()
        store.statusByKey["ageRatingChange.13"] = .denied
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: 4, current: 13)
        )

        // Then
        XCTAssertEqual(state, .denied)
        XCTAssertEqual(provider.requestCount, 0)
    }

    @MainActor func test_checkConsentIfNeeded_when_cached_pending_then_returns_pending_without_new_request() async {
        // Given
        let provider = MockConsentProvider(requestResult: .sent(questionID: UUID()))
        let store = MockConsentStore()
        store.statusByKey["ageRatingChange.13"] = .pending
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: 4, current: 13)
        )

        // Then
        XCTAssertEqual(state, .pending)
        XCTAssertEqual(provider.requestCount, 0)
    }

    @MainActor func test_checkConsentIfNeeded_when_question_sent_then_persists_pending_and_returns_pending() async {
        // Given
        let questionID = UUID()
        let provider = MockConsentProvider(requestResult: .sent(questionID: questionID))
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: 4, current: 13)
        )

        // Then
        XCTAssertEqual(state, .pending)
        XCTAssertEqual(provider.requestCount, 1)
        XCTAssertEqual(store.statusByKey["ageRatingChange.13"], .pending)
        XCTAssertEqual(
            store.pendingRequest,
            PendingConsentRequest(questionID: questionID, identifier: .ageRatingChange(ratingCode: 13))
        )
    }

    @MainActor func test_checkConsentIfNeeded_when_request_notAvailable_then_returns_notAvailable_and_stores_nothing() async {
        // Given
        let provider = MockConsentProvider(requestResult: .notAvailable)
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: 4, current: 13)
        )

        // Then
        XCTAssertEqual(state, .notAvailable)
        XCTAssertEqual(store.setCount, 0)
        XCTAssertNil(store.pendingRequest)
    }

    @MainActor func test_startObservingResponses_when_pending_question_approved_then_stores_granted_and_notifies() async {
        // Given
        let questionID = UUID()
        let provider = MockConsentProvider(requestResult: .sent(questionID: questionID))
        provider.stubbedResponses = [.init(questionID: questionID, isApproved: true)]
        let store = MockConsentStore()
        store.statusByKey["ageRatingChange.13"] = .pending
        store.pendingRequest = PendingConsentRequest(questionID: questionID, identifier: .ageRatingChange(ratingCode: 13))
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
        XCTAssertEqual(store.statusByKey["ageRatingChange.13"], .granted)
        XCTAssertNil(store.pendingRequest)
    }

    @MainActor func test_startObservingResponses_when_response_for_unknown_question_then_ignores_it() async {
        // Given
        let provider = MockConsentProvider(requestResult: .notAvailable)
        provider.stubbedResponses = [.init(questionID: UUID(), isApproved: false)]
        let store = MockConsentStore()
        store.pendingRequest = PendingConsentRequest(questionID: UUID(), identifier: .ageRatingChange(ratingCode: 13))
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
    }

    @MainActor func test_checkConsentIfNeeded_when_manual_identifier_then_takes_precedence_and_persists_pending() async {
        // Given
        let questionID = UUID()
        let provider = MockConsentProvider(requestResult: .sent(questionID: questionID))
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        // When
        let state = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: 4, current: 13),
            manualChangeIdentifier: .manual(id: "new-feature")
        )

        // Then
        XCTAssertEqual(state, .pending)
        XCTAssertEqual(store.statusByKey["manual.new-feature"], .pending)
        XCTAssertNil(store.statusByKey["ageRatingChange.13"])
        XCTAssertEqual(
            store.pendingRequest,
            PendingConsentRequest(questionID: questionID, identifier: .manual(id: "new-feature"))
        )
    }

    @MainActor func test_resetDeniedConsent_when_status_is_denied_then_clears_it() {
        // Given
        let store = MockConsentStore()
        store.statusByKey["ageRatingChange.13"] = .denied
        let sut = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(requestResult: .notAvailable),
            consentStore: store
        )

        // When
        sut.resetDeniedConsent(for: .ageRatingChange(ratingCode: 13))

        // Then
        XCTAssertNil(store.statusByKey["ageRatingChange.13"])
    }

    @MainActor func test_resetDeniedConsent_when_status_is_granted_then_keeps_it() {
        // Given
        let store = MockConsentStore()
        store.statusByKey["ageRatingChange.13"] = .granted
        let sut = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(requestResult: .notAvailable),
            consentStore: store
        )

        // When
        sut.resetDeniedConsent(for: .ageRatingChange(ratingCode: 13))

        // Then
        XCTAssertEqual(store.statusByKey["ageRatingChange.13"], .granted)
    }
}

private final class MockConsentProvider: SignificantChangeConsentProviding {
    let requestResult: SignificantChangeConsentRequestResult
    var stubbedResponses: [SignificantChangeConsentResponse] = []
    private(set) var requestCount = 0

    init(requestResult: SignificantChangeConsentRequestResult) {
        self.requestResult = requestResult
    }

    func requestConsent(
        in viewController: UIViewController,
        significantAppUpdateDescription: String
    ) async -> SignificantChangeConsentRequestResult {
        requestCount += 1
        return requestResult
    }

    func responses() -> AsyncStream<SignificantChangeConsentResponse> {
        AsyncStream { continuation in
            stubbedResponses.forEach { continuation.yield($0) }
            continuation.finish()
        }
    }
}

private final class MockConsentStore: SignificantChangeConsentStoring {
    var statusByKey: [String: SignificantChangeConsentStatus] = [:]
    var pendingRequest: PendingConsentRequest?
    private(set) var setCount = 0

    func status(for identifier: SignificantChangeIdentifier) -> SignificantChangeConsentStatus? {
        statusByKey[identifier.cacheKey]
    }

    func setStatus(_ status: SignificantChangeConsentStatus, for identifier: SignificantChangeIdentifier) {
        setCount += 1
        statusByKey[identifier.cacheKey] = status
    }

    func clearStatus(for identifier: SignificantChangeIdentifier) {
        statusByKey[identifier.cacheKey] = nil
    }

    func setPendingRequest(_ request: PendingConsentRequest) {
        pendingRequest = request
    }

    func clearPendingRequest() {
        pendingRequest = nil
    }
}
