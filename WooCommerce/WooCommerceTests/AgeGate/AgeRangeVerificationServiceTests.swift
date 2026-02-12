import XCTest
@testable import WooCommerce

final class AgeRangeVerificationServiceTests: XCTestCase {
    func test_verifyAgeRange_when_lowerBound_at_least_minimum_returns_eligible_with_minor_false() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .success(AgeRangeSnapshot(lowerBound: 20, significantAppChangeApprovalRequired: true)),
            eligibilityResult: .success(true)
        )
        let sut = AgeRangeVerificationService(provider: provider)
        let exp = expectation(description: "completion")

        sut.verifyAgeRange(in: window.rootViewController!, minimumAge: 13) { result in
            switch result {
            case let .eligible(approvalRequired, isMinor):
                XCTAssertTrue(approvalRequired)
                XCTAssertFalse(isMinor)
            default:
                XCTFail("Expected .eligible, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_verifyAgeRange_when_lowerBound_is_minor_returns_eligible_with_minor_true() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .success(AgeRangeSnapshot(lowerBound: 13, significantAppChangeApprovalRequired: false)),
            eligibilityResult: .success(true)
        )
        let sut = AgeRangeVerificationService(provider: provider)
        let exp = expectation(description: "completion")

        sut.verifyAgeRange(in: window.rootViewController!, minimumAge: 13) { result in
            switch result {
            case let .eligible(approvalRequired, isMinor):
                XCTAssertFalse(approvalRequired)
                XCTAssertTrue(isMinor)
            default:
                XCTFail("Expected .eligible, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_verifyAgeRange_when_lowerBound_below_minimum_returns_ineligible() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .success(AgeRangeSnapshot(lowerBound: 12, significantAppChangeApprovalRequired: false)),
            eligibilityResult: .success(true)
        )
        let sut = AgeRangeVerificationService(provider: provider)
        let exp = expectation(description: "completion")

        sut.verifyAgeRange(in: window.rootViewController!, minimumAge: 13) { result in
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

    func test_verifyAgeRange_when_lowerBound_is_nil_returns_ineligible() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .success(AgeRangeSnapshot(lowerBound: nil, significantAppChangeApprovalRequired: false)),
            eligibilityResult: .success(true)
        )
        let sut = AgeRangeVerificationService(provider: provider)
        let exp = expectation(description: "completion")

        sut.verifyAgeRange(in: window.rootViewController!, minimumAge: 13) { result in
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

    func test_verifyAgeRange_when_provider_declinedSharing_returns_declinedSharing() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .failure(AgeRangeProviderError.declinedSharing),
            eligibilityResult: .success(true)
        )
        let sut = AgeRangeVerificationService(provider: provider)
        let exp = expectation(description: "completion")

        sut.verifyAgeRange(in: window.rootViewController!, minimumAge: 13) { result in
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

    func test_verifyAgeRange_when_provider_unknown_returns_unknown() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .failure(AgeRangeProviderError.unknown),
            eligibilityResult: .success(true)
        )
        let sut = AgeRangeVerificationService(provider: provider)
        let exp = expectation(description: "completion")

        sut.verifyAgeRange(in: window.rootViewController!, minimumAge: 13) { result in
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

    func test_verifyAgeRange_when_provider_notAvailable_returns_sdkError() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .failure(AgeRangeProviderError.notAvailable),
            eligibilityResult: .success(true)
        )
        let sut = AgeRangeVerificationService(provider: provider)
        let exp = expectation(description: "completion")

        sut.verifyAgeRange(in: window.rootViewController!, minimumAge: 13) { result in
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

    func test_verifyAgeRange_when_eligibility_false_returns_ineligibleForAgeFeatures() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .success(AgeRangeSnapshot(lowerBound: 18, significantAppChangeApprovalRequired: false)),
            eligibilityResult: .success(false)
        )
        let sut = AgeRangeVerificationService(provider: provider)
        let exp = expectation(description: "completion")

        sut.verifyAgeRange(in: window.rootViewController!, minimumAge: 13) { result in
            switch result {
            case .ineligibleForAgeFeatures:
                break
            default:
                XCTFail("Expected .ineligibleForAgeFeatures, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

}

private final class MockAgeRangeProvider: AgeRangeProviding {
    let snapshotResult: Result<AgeRangeSnapshot, Error>
    let eligibilityResult: Result<Bool, Error>

    init(snapshotResult: Result<AgeRangeSnapshot, Error>, eligibilityResult: Result<Bool, Error>) {
        self.snapshotResult = snapshotResult
        self.eligibilityResult = eligibilityResult
    }

    func requestAgeRange(
        minimumAge: Int,
        in viewController: UIViewController
    ) async throws -> AgeRangeSnapshot {
        try snapshotResult.get()
    }

    func isEligibleForAgeFeatures() async throws -> Bool {
        try eligibilityResult.get()
    }
}

private func makeWindow() -> UIWindow {
    let window = UIWindow()
    let root = UIViewController()
    window.rootViewController = root
    window.makeKeyAndVisible()
    return window
}
