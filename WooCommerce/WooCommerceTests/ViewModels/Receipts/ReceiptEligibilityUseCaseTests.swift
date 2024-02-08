import XCTest
import Yosemite
@testable import WooCommerce

final class ReceiptEligibilityUseCaseTests: XCTestCase {

    func test_isEligibleForBackendReceipts_when_feature_flag_is_disabled_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(isBackendReceiptsEnabled: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForBackendReceipts_when_WooCommerce_version_is_incorrect_dev_version_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(isBackendReceiptsEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce",
                                              version: "8.6.0-dev-wrong-version",
                                              active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForBackendReceipts_when_WooCommerce_version_is_correct_dev_version_then_returns_true() {
        // Given
        let featureFlag = MockFeatureFlagService(isBackendReceiptsEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce",
                                              version: "8.6.0-dev",
                                              active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForBackendReceipts_when_WooCommerce_version_is_below_minimum_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(isBackendReceiptsEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce",
                                              version: "8.5",
                                              active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForBackendReceipts_when_WooCommerce_version_is_equal_or_above_minimum_then_returns_true() {
        // Given
        let featureFlag = MockFeatureFlagService(isBackendReceiptsEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce",
                                              version: "8.7.0",
                                              active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEligible)
    }
}
