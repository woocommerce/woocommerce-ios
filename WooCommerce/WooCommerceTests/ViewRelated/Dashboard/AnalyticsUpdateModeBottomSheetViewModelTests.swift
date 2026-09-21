import XCTest
import Yosemite
@testable import WooCommerce

final class AnalyticsUpdateModeBottomSheetViewModelTests: XCTestCase {
    @MainActor
    func test_handleSelection_when_mode_matches_selected_mode_then_returns_true_without_saving() async throws {
        // Given
        var didUpdate = false
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case .updateAnalyticsImportUpdateMode = action {
                didUpdate = true
            }
        }
        let viewModel = AnalyticsUpdateModeBottomSheetViewModel(siteID: 123,
                                                                selectedMode: .scheduled,
                                                                stores: stores,
                                                                onModeUpdated: { _ in })

        // When
        let shouldDismiss = try await viewModel.handleSelection(.scheduled)

        // Then
        XCTAssertTrue(shouldDismiss)
        XCTAssertFalse(didUpdate)
        XCTAssertEqual(viewModel.selectedMode, .scheduled)
        XCTAssertNil(viewModel.updatingMode)
    }

    @MainActor
    func test_handleSelection_when_update_succeeds_then_updates_selected_mode_and_notifies_dashboard() async throws {
        // Given
        var updatedMode: AnalyticsImportUpdateMode?
        var notifiedMode: AnalyticsImportUpdateMode?
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            guard case let .updateAnalyticsImportUpdateMode(_, mode, onCompletion) = action else {
                return
            }
            updatedMode = mode
            onCompletion(.success(()))
        }
        let viewModel = AnalyticsUpdateModeBottomSheetViewModel(siteID: 123,
                                                                selectedMode: .immediate,
                                                                stores: stores,
                                                                onModeUpdated: { mode in
            notifiedMode = mode
        })

        // When
        let shouldDismiss = try await viewModel.handleSelection(.scheduled)

        // Then
        XCTAssertTrue(shouldDismiss)
        XCTAssertEqual(updatedMode, .scheduled)
        XCTAssertEqual(notifiedMode, .scheduled)
        XCTAssertEqual(viewModel.selectedMode, .scheduled)
        XCTAssertNil(viewModel.updatingMode)
    }

    @MainActor
    func test_handleSelection_when_update_fails_then_keeps_selected_mode_and_throws_error() async {
        // Given
        let expectedError = NSError(domain: "test", code: 1)
        var notifiedMode: AnalyticsImportUpdateMode?
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            guard case let .updateAnalyticsImportUpdateMode(_, _, onCompletion) = action else {
                return
            }
            onCompletion(.failure(expectedError))
        }
        let viewModel = AnalyticsUpdateModeBottomSheetViewModel(siteID: 123,
                                                                selectedMode: .immediate,
                                                                stores: stores,
                                                                onModeUpdated: { mode in
            notifiedMode = mode
        })

        // When
        do {
            _ = try await viewModel.handleSelection(.scheduled)
            XCTFail("Expected handleSelection to throw.")
        } catch {
            let error = error as NSError
            XCTAssertEqual(error.domain, expectedError.domain)
            XCTAssertEqual(error.code, expectedError.code)
        }

        // Then
        XCTAssertNil(notifiedMode)
        XCTAssertEqual(viewModel.selectedMode, .immediate)
        XCTAssertNil(viewModel.updatingMode)
    }
}
