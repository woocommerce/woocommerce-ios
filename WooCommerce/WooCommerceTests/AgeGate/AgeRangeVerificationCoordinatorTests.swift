import XCTest
import Experiments
@testable import WooCommerce

final class AgeRangeVerificationCoordinatorTests: XCTestCase {
    private var originalFeatureFlagService: FeatureFlagService?

    override func setUp() {
        super.setUp()
        originalFeatureFlagService = ServiceLocator.featureFlagService

        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.ageRangeRequirementsCompliance] = true
        ServiceLocator.setFeatureFlagService(featureFlagService)
    }

    override func tearDown() {
        super.tearDown()
        // Reset to the real service after each test.
        ServiceLocator.setAgeRangeVerificationService(AgeRangeVerificationService())
        if let originalFeatureFlagService {
            ServiceLocator.setFeatureFlagService(originalFeatureFlagService)
        }
    }

    func test_triggerAgeVerificationIfNeeded_when_age_is_ineligible_then_blocks() {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        ServiceLocator.setAgeRangeVerificationService(FakeAgeRangeService(result: .ineligible, delay: 0.01))

        let sut = AgeRangeVerificationCoordinator()
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
        ServiceLocator.setAgeRangeVerificationService(FakeAgeRangeService(result: .declinedSharing, delay: 0.01))

        let sut = AgeRangeVerificationCoordinator()
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
        ServiceLocator.setAgeRangeVerificationService(FakeAgeRangeService(result: .eligible, delay: 0.01))

        let sut = AgeRangeVerificationCoordinator()
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
        ServiceLocator.setAgeRangeVerificationService(FakeAgeRangeService(result: .featureUnavailable, delay: 0.01))

        let sut = AgeRangeVerificationCoordinator()
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
        ServiceLocator.setAgeRangeVerificationService(FakeAgeRangeService(result: .sdkError(NSError(domain: "test", code: 1)), delay: 0.01))

        let sut = AgeRangeVerificationCoordinator()
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
        ServiceLocator.setAgeRangeVerificationService(FakeAgeRangeService(result: .unknown, delay: 0.01))

        let sut = AgeRangeVerificationCoordinator()
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
        ServiceLocator.setAgeRangeVerificationService(FakeAgeRangeService(result: .eligible, delay: 0.01))

        let sut = AgeRangeVerificationCoordinator()
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
