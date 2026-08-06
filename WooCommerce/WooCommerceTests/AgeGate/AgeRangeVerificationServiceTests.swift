import XCTest
@testable import WooCommerce

final class AgeRangeVerificationServiceTests: XCTestCase {
    func test_verifyAgeRange_when_lowerBound_at_least_minimum_returns_eligible_with_minor_false() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .success(AgeRangeSnapshot(lowerBound: 20, significantAppChangeApprovalRequired: true)),
            requirementsResult: .success(.required())
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
            requirementsResult: .success(.required())
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
            requirementsResult: .success(.required())
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
            requirementsResult: .success(.required())
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
            requirementsResult: .success(.required())
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
            requirementsResult: .success(.required())
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
            requirementsResult: .success(.required())
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

    func test_verifyAgeRange_when_compliance_is_not_required_returns_ineligibleForAgeFeatures() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .success(AgeRangeSnapshot(lowerBound: 18, significantAppChangeApprovalRequired: false)),
            requirementsResult: .success(.notRequired())
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
        XCTAssertEqual(provider.requestCallCount, 0)
    }

    func test_verifyAgeRange_when_requirements_include_parental_consent_uses_requirements_value() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .success(AgeRangeSnapshot(lowerBound: 13, significantAppChangeApprovalRequired: false)),
            requirementsResult: .success(.required(significantAppChangeApprovalRequired: true))
        )
        let sut = AgeRangeVerificationService(provider: provider)
        let exp = expectation(description: "completion")

        sut.verifyAgeRange(in: window.rootViewController!, minimumAge: 13) { result in
            switch result {
            case let .eligible(approvalRequired, isMinor):
                XCTAssertTrue(approvalRequired)
                XCTAssertTrue(isMinor)
            default:
                XCTFail("Expected .eligible, got \(result)")
            }
            exp.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_verifyAgeRange_when_called_concurrently_coalesces_provider_requests() {
        let window = makeWindow()
        let provider = MockAgeRangeProvider(
            snapshotResult: .success(AgeRangeSnapshot(lowerBound: 20, significantAppChangeApprovalRequired: false)),
            requirementsResult: .success(.required()),
            requirementsDelayNanoseconds: 100_000_000
        )
        let sut = AgeRangeVerificationService(provider: provider)
        let exp = expectation(description: "completion")
        exp.expectedFulfillmentCount = 2

        for _ in 0..<2 {
            sut.verifyAgeRange(in: window.rootViewController!, minimumAge: 13) { result in
                guard case .eligible = result else {
                    XCTFail("Expected .eligible, got \(result)")
                    exp.fulfill()
                    return
                }
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(provider.requirementsCallCount, 1)
        XCTAssertEqual(provider.requestCallCount, 1)
    }
}

private final class MockAgeRangeProvider: AgeRangeProviding, @unchecked Sendable {
    let snapshotResult: Result<AgeRangeSnapshot, Error>
    let requirementsResult: Result<AgeRangeRequirements, Error>
    let requirementsDelayNanoseconds: UInt64

    private let stateQueue = DispatchQueue(label: "com.automattic.woocommerce.age-range-provider-mock")
    private var _requestCallCount = 0
    private var _requirementsCallCount = 0

    var requestCallCount: Int {
        stateQueue.sync { _requestCallCount }
    }

    var requirementsCallCount: Int {
        stateQueue.sync { _requirementsCallCount }
    }

    init(
        snapshotResult: Result<AgeRangeSnapshot, Error>,
        requirementsResult: Result<AgeRangeRequirements, Error>,
        requirementsDelayNanoseconds: UInt64 = 0
    ) {
        self.snapshotResult = snapshotResult
        self.requirementsResult = requirementsResult
        self.requirementsDelayNanoseconds = requirementsDelayNanoseconds
    }

    @MainActor
    func requestAgeRange(
        minimumAge: Int,
        in viewController: UIViewController
    ) async throws -> AgeRangeSnapshot {
        stateQueue.sync { _requestCallCount += 1 }
        return try snapshotResult.get()
    }

    func retrieveAgeRangeRequirements() async throws -> AgeRangeRequirements {
        stateQueue.sync { _requirementsCallCount += 1 }
        if requirementsDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: requirementsDelayNanoseconds)
        }
        return try requirementsResult.get()
    }
}

private extension AgeRangeRequirements {
    static func required(significantAppChangeApprovalRequired: Bool? = nil) -> AgeRangeRequirements {
        AgeRangeRequirements(
            isComplianceRequired: true,
            significantAppChangeApprovalRequired: significantAppChangeApprovalRequired
        )
    }

    static func notRequired() -> AgeRangeRequirements {
        AgeRangeRequirements(
            isComplianceRequired: false,
            significantAppChangeApprovalRequired: nil
        )
    }
}

private func makeWindow() -> UIWindow {
    let window = UIWindow()
    let root = UIViewController()
    window.rootViewController = root
    window.makeKeyAndVisible()
    return window
}
