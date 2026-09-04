import Combine
import Foundation
import Testing
import UIKit
import Yosemite
@testable import WooCommerce

/// Serialized because the tests suspend while waiting for main-queue delivery, and the session managers
/// they build share one UserDefaults suite.
///
@Suite(.serialized)
@MainActor
struct StoreConnectionErrorViewModelTests {
    private let sessionManager: SessionManager
    private let stores: MockStoresManager
    private let monitor: MockStoreConnectionErrorMonitor
    private let notificationCenter: NotificationCenter

    init() {
        sessionManager = .makeForTesting(authenticated: true)
        stores = MockStoresManager(sessionManager: sessionManager)
        monitor = MockStoreConnectionErrorMonitor()
        notificationCenter = NotificationCenter()
    }

    @Test func test_presentedSiteID_when_no_store_is_affected_then_it_is_nil() async {
        // Given
        sessionManager.defaultStoreID = 123

        // When
        let viewModel = makeViewModel()
        await settle()

        // Then
        #expect(viewModel.presentedSiteID == nil)
    }

    @Test func test_presentedSiteID_when_the_selected_store_is_affected_then_it_is_that_store() async {
        // Given
        sessionManager.defaultStoreID = 123
        let viewModel = makeViewModel()

        // When
        monitor.simulateAffectedSiteID(123)
        await settle()

        // Then
        #expect(viewModel.presentedSiteID == 123)
    }

    @Test func test_presentedSiteID_when_another_store_is_affected_then_it_is_nil() async {
        // Given
        sessionManager.defaultStoreID = 123
        let viewModel = makeViewModel()

        // When
        monitor.simulateAffectedSiteID(456)
        await settle()

        // Then
        #expect(viewModel.presentedSiteID == nil)
    }

    @Test func test_presentedSiteID_when_the_affected_store_recovers_then_it_becomes_nil() async {
        // Given
        sessionManager.defaultStoreID = 123
        let viewModel = makeViewModel()
        monitor.simulateAffectedSiteID(123)
        await settle()

        // When
        monitor.simulateAffectedSiteID(nil)
        await settle()

        // Then
        #expect(viewModel.presentedSiteID == nil)
    }

    @Test func test_presentedSiteID_when_switching_to_the_affected_store_then_it_becomes_that_store() async {
        // Given
        sessionManager.defaultStoreID = 123
        let viewModel = makeViewModel()
        monitor.simulateAffectedSiteID(456)
        await settle()

        // When
        sessionManager.defaultStoreID = 456
        await settle()

        // Then
        #expect(viewModel.presentedSiteID == 456)
    }

    @Test func test_dismissTapped_when_the_store_is_still_affected_then_it_hides_the_warning() async {
        // Given
        sessionManager.defaultStoreID = 123
        let viewModel = makeViewModel()
        monitor.simulateAffectedSiteID(123)
        await settle()

        // When
        viewModel.dismissTapped()
        await settle()

        // Then
        #expect(viewModel.presentedSiteID == nil)
    }

    @Test func test_dismissTapped_when_the_app_returns_to_the_foreground_then_the_warning_comes_back() async {
        // Given
        sessionManager.defaultStoreID = 123
        let viewModel = makeViewModel()
        monitor.simulateAffectedSiteID(123)
        await settle()
        viewModel.dismissTapped()
        await settle()

        // When
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        await settle()

        // Then
        #expect(viewModel.presentedSiteID == 123)
    }

    @Test func test_dismissTapped_when_switching_away_and_back_then_the_warning_stays_hidden() async {
        // Given
        sessionManager.defaultStoreID = 123
        let viewModel = makeViewModel()
        monitor.simulateAffectedSiteID(123)
        await settle()
        viewModel.dismissTapped()
        await settle()

        // When
        sessionManager.defaultStoreID = 456
        await settle()
        sessionManager.defaultStoreID = 123
        await settle()

        // Then
        #expect(viewModel.presentedSiteID == nil)
    }

    @Test func test_dismissTapped_when_another_store_becomes_affected_then_the_warning_is_shown_for_it() async {
        // Given
        sessionManager.defaultStoreID = 123
        let viewModel = makeViewModel()
        monitor.simulateAffectedSiteID(123)
        await settle()
        viewModel.dismissTapped()
        await settle()

        // When
        // The affected store moves straight from one to another without recovering in between.
        monitor.simulateAffectedSiteID(456)
        sessionManager.defaultStoreID = 456
        await settle()

        // Then
        #expect(viewModel.presentedSiteID == 456)
    }

    @Test func test_dismissTapped_when_the_store_recovers_and_fails_again_then_the_warning_comes_back() async {
        // Given
        sessionManager.defaultStoreID = 123
        let viewModel = makeViewModel()
        monitor.simulateAffectedSiteID(123)
        await settle()
        viewModel.dismissTapped()
        await settle()

        // When
        monitor.simulateAffectedSiteID(nil)
        await settle()
        monitor.simulateAffectedSiteID(123)
        await settle()

        // Then
        #expect(viewModel.presentedSiteID == 123)
    }

    /// The monitor can move on before the view model has processed the change it is currently showing,
    /// so Dismiss has to silence the store the merchant actually saw, not whatever is affected now.
    ///
    @Test func test_dismissTapped_when_the_monitor_has_moved_on_then_it_snoozes_the_store_that_was_shown() async {
        // Given
        sessionManager.defaultStoreID = 123
        let viewModel = makeViewModel()
        monitor.simulateAffectedSiteID(123)
        await settle()

        // When
        // No settle here: the change is queued but unprocessed when the merchant taps Dismiss.
        monitor.simulateAffectedSiteID(456)
        viewModel.dismissTapped()
        await settle()

        // Then
        // 456 was never shown, so switching to it has to surface the warning.
        sessionManager.defaultStoreID = 456
        await settle()
        #expect(viewModel.presentedSiteID == 456)
    }
}

private extension StoreConnectionErrorViewModelTests {
    func makeViewModel() -> StoreConnectionErrorViewModel {
        StoreConnectionErrorViewModel(monitor: monitor,
                                      stores: stores,
                                      notificationCenter: notificationCenter)
    }

    /// Lets the view model's scheduled work run before the assertion does.
    ///
    /// Two hand-offs to the main queue can sit between a change and `presentedSiteID` settling: the monitor
    /// and the foreground notification each deliver on main, and the view model then delivers its own
    /// combined result there too. Draining twice covers the longest of those chains. Everything is
    /// queued on main in order, so this is deterministic rather than a sleep.
    ///
    func settle() async {
        for _ in 0..<2 {
            await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    continuation.resume()
                }
            }
        }
    }
}
