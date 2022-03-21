import XCTest
@testable import enum Yosemite.SettingAction
@testable import WooCommerce

final class EnableAnalyticsViewModelTests: XCTestCase {

    func test_enableAnalytics_triggers_onSuccess_if_request_succeeds() {
        // Given
        let sampleSiteID: Int64 = 135
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = EnableAnalyticsViewModel(siteID: sampleSiteID, stores: stores)
        var onSuccessTriggered = false
        var onFailureTriggered = false
        let onSuccess: () -> Void = {
            onSuccessTriggered = true
        }
        let onFailure: () -> Void = {
            onFailureTriggered = true
        }

        // When
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .enableAnalyticsSetting(siteID, onCompletion):
                XCTAssertEqual(sampleSiteID, siteID) // confidence check
                onCompletion(.success(()))
            default:
                break
            }
        }
        viewModel.enableAnalytics(onSuccess: onSuccess, onFailure: onFailure)

        // Then
        XCTAssertTrue(onSuccessTriggered)
        XCTAssertFalse(onFailureTriggered)
    }

    func test_enableAnalytics_triggers_onSuccess_if_request_succeeds_on_second_try() {
        // Given
        let sampleSiteID: Int64 = 135
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = EnableAnalyticsViewModel(siteID: sampleSiteID, stores: stores)
        var onSuccessTriggered = false
        var onFailureTriggered = false
        let onSuccess: () -> Void = {
            onSuccessTriggered = true
        }
        let onFailure: () -> Void = {
            onFailureTriggered = true
        }
        var retries = 0

        // When
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .enableAnalyticsSetting(_, onCompletion):
                if retries == 0 {
                    retries += 1
                    let error = NSError(domain: "Test", code: 400, userInfo: nil)
                    onCompletion(.failure(error))
                } else {
                    onCompletion(.success(()))
                }
            default:
                break
            }
        }
        viewModel.enableAnalytics(onSuccess: onSuccess, onFailure: onFailure)

        // Then
        XCTAssertTrue(onSuccessTriggered)
        XCTAssertFalse(onFailureTriggered)
    }

    func test_enableAnalytics_triggers_onFailure_if_request_fails_on_both_tries() {
        // Given
        let sampleSiteID: Int64 = 135
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = EnableAnalyticsViewModel(siteID: sampleSiteID, stores: stores)
        var onSuccessTriggered = false
        var onFailureTriggered = false
        let onSuccess: () -> Void = {
            onSuccessTriggered = true
        }
        let onFailure: () -> Void = {
            onFailureTriggered = true
        }

        // When
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .enableAnalyticsSetting(_, onCompletion):
                let error = NSError(domain: "Test", code: 400, userInfo: nil)
                onCompletion(.failure(error))
            default:
                break
            }
        }
        viewModel.enableAnalytics(onSuccess: onSuccess, onFailure: onFailure)

        // Then
        XCTAssertFalse(onSuccessTriggered)
        XCTAssertTrue(onFailureTriggered)
    }
}
