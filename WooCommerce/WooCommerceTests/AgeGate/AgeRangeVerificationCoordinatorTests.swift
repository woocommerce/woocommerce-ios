import XCTest
import Experiments
@testable import WooCommerce

final class AgeRangeVerificationCoordinatorTests: XCTestCase {
    private var featureFlagService: FeatureFlagService!
    private var consentCoordinator: SignificantChangeConsentCoordinator!
    private var ageRatingChangeDetector: AgeRatingChangeDetecting!

    override func setUp() {
        super.setUp()
        featureFlagService = AlwaysOnFeatureFlagService()
        consentCoordinator = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(requestResult: .notAvailable),
            consentStore: MockConsentStore()
        )
        ageRatingChangeDetector = MockAgeRatingChangeDetector(result: nil)
    }

    override func tearDown() {
        featureFlagService = nil
        consentCoordinator = nil
        ageRatingChangeDetector = nil
        super.tearDown()
    }

    func test_triggerAgeVerificationIfNeeded_when_age_is_ineligible_then_blocks() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        let sut = AgeRangeVerificationCoordinator(
            featureFlagService: featureFlagService,
            ageRangeVerificationService: FakeAgeRangeService(
                result: .ineligible,
                delay: 0.01
            ),
            significantChangeConsentCoordinator: consentCoordinator,
            ageRatingChangeDetector: ageRatingChangeDetector
        )
        let exp = expectation(description: "onResult")

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDecision, result in
            XCTAssertEqual(appAccessDecision, .denyAndLogout)
            switch result {
            case .ineligible:
                break
            default:
                XCTFail("Expected .ineligible, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_triggerAgeVerificationIfNeeded_when_age_is_declinedSharing_then_allows() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        let sut = AgeRangeVerificationCoordinator(
            featureFlagService: featureFlagService,
            ageRangeVerificationService: FakeAgeRangeService(
                result: .declinedSharing,
                delay: 0.01
            ),
            significantChangeConsentCoordinator: consentCoordinator,
            ageRatingChangeDetector: ageRatingChangeDetector
        )
        let exp = expectation(description: "onResult")

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDecision, result in
            XCTAssertEqual(appAccessDecision, .allow) // per current logic: declined → allow
            switch result {
            case .declinedSharing:
                break
            default:
                XCTFail("Expected .declinedSharing, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_triggerAgeVerificationIfNeeded_when_anchor_missing_then_allows() {
        let window = UIWindow() // no rootViewController
        let sut = AgeRangeVerificationCoordinator(
            featureFlagService: featureFlagService,
            ageRangeVerificationService: FakeAgeRangeService(
                result: .invalidUIState,
                delay: 0.01
            ),
            significantChangeConsentCoordinator: consentCoordinator,
            ageRatingChangeDetector: ageRatingChangeDetector
        )
        let exp = expectation(description: "onResult")

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDecision, result in
            XCTAssertEqual(appAccessDecision, .allow) // we allow when no presenter is available
            switch result {
            case .invalidUIState:
                break
            default:
                XCTFail("Expected .invalidUIState, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_triggerAgeVerificationIfNeeded_when_featureUnavailable_then_allows() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        let sut = AgeRangeVerificationCoordinator(
            featureFlagService: featureFlagService,
            ageRangeVerificationService: FakeAgeRangeService(
                result: .featureUnavailable,
                delay: 0.01
            ),
            significantChangeConsentCoordinator: consentCoordinator,
            ageRatingChangeDetector: ageRatingChangeDetector
        )
        let exp = expectation(description: "onResult")

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDecision, result in
            XCTAssertEqual(appAccessDecision, .allow) // per current logic: featureUnavailable → allow
            switch result {
            case .featureUnavailable:
                break
            default:
                XCTFail("Expected .featureUnavailable, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_triggerAgeVerificationIfNeeded_when_sdkError_then_allows() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        let sut = AgeRangeVerificationCoordinator(
            featureFlagService: featureFlagService,
            ageRangeVerificationService: FakeAgeRangeService(
                result: .sdkError(
                    NSError(
                        domain: "test",
                        code: 1
                    )
                ),
                delay: 0.01
            ),
            significantChangeConsentCoordinator: consentCoordinator,
            ageRatingChangeDetector: ageRatingChangeDetector
        )
        let exp = expectation(description: "onResult")

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDecision, result in
            XCTAssertEqual(appAccessDecision, .allow) // per current logic: sdkError → allow
            switch result {
            case .sdkError:
                break
            default:
                XCTFail("Expected .sdkError, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_triggerAgeVerificationIfNeeded_when_unknown_then_allows() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        let sut = AgeRangeVerificationCoordinator(
            featureFlagService: featureFlagService,
            ageRangeVerificationService: FakeAgeRangeService(
                result: .unknown,
                delay: 0.01
            ),
            significantChangeConsentCoordinator: consentCoordinator,
            ageRatingChangeDetector: ageRatingChangeDetector
        )
        let exp = expectation(description: "onResult")

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDecision, result in
            XCTAssertEqual(appAccessDecision, .allow) // per current logic: unknown → allow
            switch result {
            case .unknown:
                break
            default:
                XCTFail("Expected .unknown, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_triggerAgeVerificationIfNeeded_when_age_is_eligible_then_allows() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        let sut = AgeRangeVerificationCoordinator(
            featureFlagService: featureFlagService,
            ageRangeVerificationService: FakeAgeRangeService(
                result: .eligible(
                    significantAppChangeApprovalRequired: false,
                    isMinor: false
                ),
                delay: 0.01
            ),
            significantChangeConsentCoordinator: consentCoordinator,
            ageRatingChangeDetector: ageRatingChangeDetector
        )
        let exp = expectation(description: "onResult")

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDecision, result in
            XCTAssertEqual(appAccessDecision, .allow)
            switch result {
            case .eligible:
                break
            default:
                XCTFail("Expected .eligible, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_triggerAgeVerificationIfNeeded_when_minor_and_consent_denied_then_restricts_without_logout() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        featureFlagService = AlwaysOnFeatureFlagService()
        let consentStore = MockConsentStore()
        consentStore.statusByKey["ageRatingChange.13"] = .denied
        consentCoordinator = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(requestResult: .notAvailable),
            consentStore: consentStore
        )
        ageRatingChangeDetector = MockAgeRatingChangeDetector(result: .ageRatingChanged(previous: 4, current: 13))
        let sut = AgeRangeVerificationCoordinator(
            featureFlagService: featureFlagService,
            ageRangeVerificationService: FakeAgeRangeService(
                result: .eligible(
                    significantAppChangeApprovalRequired: true,
                    isMinor: true
                ),
                delay: 0.01
            ),
            significantChangeConsentCoordinator: consentCoordinator,
            ageRatingChangeDetector: ageRatingChangeDetector
        )
        let exp = expectation(description: "onResult")

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDecision, result in
            XCTAssertEqual(appAccessDecision, .restrictDeniedConsent)
            switch result {
            case .eligible:
                break
            default:
                XCTFail("Expected .eligible, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_triggerAgeVerificationIfNeeded_when_minor_and_question_sent_then_restricts_pending_consent() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        featureFlagService = AlwaysOnFeatureFlagService()
        consentCoordinator = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(requestResult: .sent(questionID: UUID())),
            consentStore: MockConsentStore()
        )
        ageRatingChangeDetector = MockAgeRatingChangeDetector(result: .ageRatingChanged(previous: 4, current: 13))
        let sut = AgeRangeVerificationCoordinator(
            featureFlagService: featureFlagService,
            ageRangeVerificationService: FakeAgeRangeService(
                result: .eligible(
                    significantAppChangeApprovalRequired: true,
                    isMinor: true
                ),
                delay: 0.01
            ),
            significantChangeConsentCoordinator: consentCoordinator,
            ageRatingChangeDetector: ageRatingChangeDetector
        )
        let exp = expectation(description: "onResult")

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDecision, _ in
            XCTAssertEqual(appAccessDecision, .restrictPendingConsent)
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_triggerAgeVerificationIfNeeded_when_minor_and_consent_granted_then_allows_and_acknowledges_change() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        featureFlagService = AlwaysOnFeatureFlagService()
        let consentStore = MockConsentStore()
        consentStore.statusByKey["ageRatingChange.13"] = .granted
        consentCoordinator = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(requestResult: .notAvailable),
            consentStore: consentStore
        )
        let detector = MockAgeRatingChangeDetector(result: .ageRatingChanged(previous: 4, current: 13))
        ageRatingChangeDetector = detector
        let sut = AgeRangeVerificationCoordinator(
            featureFlagService: featureFlagService,
            ageRangeVerificationService: FakeAgeRangeService(
                result: .eligible(
                    significantAppChangeApprovalRequired: true,
                    isMinor: true
                ),
                delay: 0.01
            ),
            significantChangeConsentCoordinator: consentCoordinator,
            ageRatingChangeDetector: ageRatingChangeDetector
        )
        let exp = expectation(description: "onResult")

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDecision, result in
            XCTAssertEqual(appAccessDecision, .allow)
            switch result {
            case .eligible:
                break
            default:
                XCTFail("Expected .eligible, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(detector.acknowledgedRatingCode, 13)
    }
}

private final class MockAgeRatingChangeDetector: AgeRatingChangeDetecting {
    let result: AgeRatingChangeCheckResult?
    private(set) var acknowledgedRatingCode: Int?
    init(result: AgeRatingChangeCheckResult?) {
        self.result = result
    }
    func checkForChange() async -> AgeRatingChangeCheckResult? { result }
    func acknowledge(ratingCode: Int) {
        acknowledgedRatingCode = ratingCode
    }
}

private final class MockConsentProvider: SignificantChangeConsentProviding {
    let requestResult: SignificantChangeConsentRequestResult
    init(requestResult: SignificantChangeConsentRequestResult) {
        self.requestResult = requestResult
    }
    func requestConsent(
        in viewController: UIViewController,
        significantAppUpdateDescription: String
    ) async -> SignificantChangeConsentRequestResult {
        requestResult
    }
    func responses() -> AsyncStream<SignificantChangeConsentResponse> {
        AsyncStream { $0.finish() }
    }
}

private final class MockConsentStore: SignificantChangeConsentStoring {
    var statusByKey: [String: SignificantChangeConsentStatus] = [:]
    var pendingRequest: PendingConsentRequest?

    func status(for identifier: SignificantChangeIdentifier) -> SignificantChangeConsentStatus? {
        statusByKey[identifier.cacheKey]
    }
    func setStatus(_ status: SignificantChangeConsentStatus, for identifier: SignificantChangeIdentifier) {
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

private struct FakeAgeRangeService: AgeRangeVerificationServiceProtocol {
    let result: AgeRangeVerificationResult
    let delay: TimeInterval
    func verifyAgeRange(
        in viewController: UIViewController,
        minimumAge: Int,
        completion: @escaping (AgeRangeVerificationResult) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            completion(result)
        }
    }
}

private struct AlwaysOnFeatureFlagService: FeatureFlagService {
    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool { true }
}
