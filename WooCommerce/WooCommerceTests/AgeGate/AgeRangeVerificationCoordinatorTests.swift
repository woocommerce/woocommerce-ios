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
            consentProvider: MockConsentProvider(outcome: .granted),
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

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDescision, result in
            XCTAssertEqual(appAccessDescision, .denyAndLogout)
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

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDescision, result in
            XCTAssertEqual(appAccessDescision, .allow) // per current logic: declined → allow
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

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDescision, result in
            XCTAssertEqual(appAccessDescision, .allow) // we allow when no presenter is available
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

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDescision, result in
            XCTAssertEqual(appAccessDescision, .allow) // per current logic: featureUnavailable → allow
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

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDescision, result in
            XCTAssertEqual(appAccessDescision, .allow) // per current logic: sdkError → allow
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

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDescision, result in
            XCTAssertEqual(appAccessDescision, .allow) // per current logic: unknown → allow
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

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDescision, result in
            XCTAssertEqual(appAccessDescision, .allow)
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

    func test_triggerAgeVerificationIfNeeded_when_minor_and_approval_required_then_denied_blocks() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        featureFlagService = AlwaysOnFeatureFlagService()
        consentCoordinator = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(outcome: .denied),
            consentStore: MockConsentStore()
        )
        ageRatingChangeDetector = MockAgeRatingChangeDetector(result: .ageRatingChanged(previous: nil, current: 13))
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

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDescision, result in
            XCTAssertEqual(appAccessDescision, .denyAndLogout)
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

    func test_triggerAgeVerificationIfNeeded_when_minor_and_approval_required_then_granted_allows() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        featureFlagService = AlwaysOnFeatureFlagService()
        consentCoordinator = SignificantChangeConsentCoordinator(
            consentProvider: MockConsentProvider(outcome: .granted),
            consentStore: MockConsentStore()
        )
        ageRatingChangeDetector = MockAgeRatingChangeDetector(result: .ageRatingChanged(previous: nil, current: 13))
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

        sut.triggerAgeVerificationIfNeeded(hostingWindow: window) { appAccessDescision, result in
            XCTAssertEqual(appAccessDescision, .allow)
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
}

private struct MockAgeRatingChangeDetector: AgeRatingChangeDetecting {
    let result: AgeRatingChangeCheckResult?
    func checkForChange() async -> AgeRatingChangeCheckResult? { result }
}

private final class MockConsentProvider: SignificantChangeConsentProviding {
    let outcome: SignificantChangeConsentOutcome
    init(outcome: SignificantChangeConsentOutcome) {
        self.outcome = outcome
    }
    func requestConsent(
        in viewController: UIViewController,
        significantAppUpdateDescription: String
    ) async -> SignificantChangeConsentOutcome {
        outcome
    }
}

private final class MockConsentStore: SignificantChangeConsentStoring {
    func status(for identifier: SignificantChangeIdentifier) -> SignificantChangeConsentStatus? { nil }
    func setStatus(_ status: SignificantChangeConsentStatus, for identifier: SignificantChangeIdentifier) {}
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
