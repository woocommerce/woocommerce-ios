import XCTest
@testable import WooCommerce

final class SignificantChangeConsentCoordinatorTests: XCTestCase {

    func test_checkConsentIfNeeded_when_not_minor_returns_granted_without_request() async {
        let provider = MockConsentProvider(outcome: .denied)
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        let outcome = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: nil, current: 13)
        )

        XCTAssertEqual(outcome, .denied)
        XCTAssertEqual(provider.requestCount, 1)
        XCTAssertEqual(store.setCount, 1)
    }

    func test_checkConsentIfNeeded_when_no_change_returns_granted() async {
        let provider = MockConsentProvider(outcome: .denied)
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        let outcome = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: nil
        )

        XCTAssertEqual(outcome, .granted)
        XCTAssertEqual(provider.requestCount, 0)
        XCTAssertEqual(store.setCount, 0)
    }

    func test_checkConsentIfNeeded_when_cached_granted_returns_granted_without_request() async {
        let provider = MockConsentProvider(outcome: .denied)
        let store = MockConsentStore()
        let identifier = SignificantChangeIdentifier.ageRatingChange(ratingCode: 13)
        store.statusByKey[identifier.cacheKey] = .granted
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        let outcome = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: nil, current: 13)
        )

        XCTAssertEqual(outcome, .granted)
        XCTAssertEqual(provider.requestCount, 0)
        XCTAssertEqual(store.setCount, 0)
    }

    func test_checkConsentIfNeeded_when_cached_denied_returns_denied_without_request() async {
        let provider = MockConsentProvider(outcome: .granted)
        let store = MockConsentStore()
        let identifier = SignificantChangeIdentifier.ageRatingChange(ratingCode: 13)
        store.statusByKey[identifier.cacheKey] = .denied
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        let outcome = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: nil, current: 13)
        )

        XCTAssertEqual(outcome, .denied)
        XCTAssertEqual(provider.requestCount, 0)
        XCTAssertEqual(store.setCount, 0)
    }

    func test_checkConsentIfNeeded_when_provider_grants_caches_and_returns_granted() async {
        let provider = MockConsentProvider(outcome: .granted)
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        let outcome = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: nil, current: 13)
        )

        XCTAssertEqual(outcome, .granted)
        XCTAssertEqual(store.setCount, 1)
        XCTAssertEqual(store.statusByKey["ageRatingChange.13"], .granted)
    }

    func test_checkConsentIfNeeded_when_provider_denies_caches_and_returns_denied() async {
        let provider = MockConsentProvider(outcome: .denied)
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        let outcome = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: .ageRatingChanged(previous: nil, current: 13)
        )

        XCTAssertEqual(outcome, .denied)
        XCTAssertEqual(store.setCount, 1)
        XCTAssertEqual(store.statusByKey["ageRatingChange.13"], .denied)
    }

    func test_checkConsentIfNeeded_when_manual_identifier_uses_manual_path() async {
        let provider = MockConsentProvider(outcome: .granted)
        let store = MockConsentStore()
        let sut = SignificantChangeConsentCoordinator(consentProvider: provider, consentStore: store)

        let outcome = await sut.checkConsentIfNeeded(
            in: UIViewController(),
            ageRatingChange: nil,
            manualChangeIdentifier: .manual(id: "new-feature")
        )

        XCTAssertEqual(outcome, .granted)
        XCTAssertEqual(store.setCount, 1)
        XCTAssertEqual(store.statusByKey["manual.new-feature"], .granted)
    }
}

private final class MockConsentProvider: SignificantChangeConsentProviding {
    let outcome: SignificantChangeConsentOutcome
    private(set) var requestCount = 0

    init(outcome: SignificantChangeConsentOutcome) {
        self.outcome = outcome
    }

    func requestConsent(
        in viewController: UIViewController,
        significantAppUpdateDescription: String
    ) async -> SignificantChangeConsentOutcome {
        requestCount += 1
        return outcome
    }
}

private final class MockConsentStore: SignificantChangeConsentStoring {
    var statusByKey: [String: SignificantChangeConsentStatus] = [:]
    private(set) var setCount = 0

    func status(for identifier: SignificantChangeIdentifier) -> SignificantChangeConsentStatus? {
        statusByKey[identifier.cacheKey]
    }

    func setStatus(_ status: SignificantChangeConsentStatus, for identifier: SignificantChangeIdentifier) {
        setCount += 1
        statusByKey[identifier.cacheKey] = status
    }
}
