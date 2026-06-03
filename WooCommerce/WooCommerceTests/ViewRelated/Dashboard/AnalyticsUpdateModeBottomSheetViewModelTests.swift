import XCTest
import Yosemite
@testable import WooCommerce

final class AnalyticsUpdateModeBottomSheetViewModelTests: XCTestCase {
    @MainActor
    func test_handleSelection_when_mode_matches_selected_mode_then_returns_true_without_saving() async {
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
        let shouldDismiss = await viewModel.handleSelection(.scheduled)

        // Then
        XCTAssertTrue(shouldDismiss)
        XCTAssertFalse(didUpdate)
        XCTAssertEqual(viewModel.selectedMode, .scheduled)
        XCTAssertNil(viewModel.updatingMode)
        XCTAssertNil(viewModel.updateError)
    }

    @MainActor
    func test_handleSelection_when_update_succeeds_then_updates_selected_mode_and_notifies_dashboard() async {
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
        let shouldDismiss = await viewModel.handleSelection(.scheduled)

        // Then
        XCTAssertTrue(shouldDismiss)
        XCTAssertEqual(updatedMode, .scheduled)
        XCTAssertEqual(notifiedMode, .scheduled)
        XCTAssertEqual(viewModel.selectedMode, .scheduled)
        XCTAssertNil(viewModel.updatingMode)
        XCTAssertNil(viewModel.updateError)
    }

    @MainActor
    func test_handleSelection_when_update_fails_then_keeps_selected_mode_and_sets_error() async {
        // Given
        let error = NSError(domain: "test", code: 1)
        var notifiedMode: AnalyticsImportUpdateMode?
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            guard case let .updateAnalyticsImportUpdateMode(_, _, onCompletion) = action else {
                return
            }
            onCompletion(.failure(error))
        }
        let viewModel = AnalyticsUpdateModeBottomSheetViewModel(siteID: 123,
                                                                selectedMode: .immediate,
                                                                stores: stores,
                                                                onModeUpdated: { mode in
            notifiedMode = mode
        })

        // When
        let shouldDismiss = await viewModel.handleSelection(.scheduled)

        // Then
        XCTAssertFalse(shouldDismiss)
        XCTAssertNil(notifiedMode)
        XCTAssertEqual(viewModel.selectedMode, .immediate)
        XCTAssertNil(viewModel.updatingMode)
        XCTAssertNotNil(viewModel.updateError)
    }
}
