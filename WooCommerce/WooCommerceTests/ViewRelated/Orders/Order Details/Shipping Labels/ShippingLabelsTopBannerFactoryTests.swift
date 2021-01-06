import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelsTopBannerFactoryTests: XCTestCase {
    func test_creating_top_banner_with_empty_shipping_labels_returns_nil() throws {
        // Given
        let factory = ShippingLabelsTopBannerFactory(shippingLabels: [])

        // When
        let topBannerView = try waitFor { promise in
            factory.createTopBannerIfNeeded(isExpanded: false,
                                            onCompletion: { topBannerView in
                                                promise(topBannerView)
                                            })
        }

        // Then
        XCTAssertNil(topBannerView)
    }

    func test_creating_top_banner_with_a_refunded_shipping_label_returns_nil() throws {
        // Given
        let refundedShippingLabel = MockShippingLabel.emptyLabel().copy(refund: .init(dateRequested: Date(), status: .pending))
        let factory = ShippingLabelsTopBannerFactory(shippingLabels: [refundedShippingLabel])

        // When
        let topBannerView = try waitFor { promise in
            factory.createTopBannerIfNeeded(isExpanded: false,
                                            onCompletion: { topBannerView in
                                                promise(topBannerView)
                                            })
        }

        // Then
        XCTAssertNil(topBannerView)
    }

    func test_creating_top_banner_with_a_non_refunded_shipping_label_and_visible_feedback_settings_returns_banner() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refund: nil)
        let stores = createStores(feedbackVisibilityResult: .success(true))
        let factory = ShippingLabelsTopBannerFactory(shippingLabels: [shippingLabel], stores: stores)

        // When
        let topBannerView = try waitFor { promise in
            factory.createTopBannerIfNeeded(isExpanded: false,
                                            onCompletion: { topBannerView in
                                                promise(topBannerView)
                                            })
        }

        // Then
        XCTAssertNotNil(topBannerView)
    }

    func test_creating_top_banner_with_a_non_refunded_shipping_label_and_invisible_feedback_settings_returns_nil() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refund: nil)
        let stores = createStores(feedbackVisibilityResult: .success(false))
        let factory = ShippingLabelsTopBannerFactory(shippingLabels: [shippingLabel], stores: stores)

        // When
        let topBannerView = try waitFor { promise in
            factory.createTopBannerIfNeeded(isExpanded: false,
                                            onCompletion: { topBannerView in
                                                promise(topBannerView)
                                            })
        }

        // Then
        XCTAssertNil(topBannerView)
    }

    func test_creating_top_banner_with_a_non_refunded_shipping_label_and_failed_feedback_settings_returns_nil() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refund: nil)
        let stores = createStores(feedbackVisibilityResult: .failure(SampleError.first))
        let factory = ShippingLabelsTopBannerFactory(shippingLabels: [shippingLabel], stores: stores)

        // When
        let topBannerView = try waitFor { promise in
            factory.createTopBannerIfNeeded(isExpanded: false,
                                            onCompletion: { topBannerView in
                                                promise(topBannerView)
                                            })
        }

        // Then
        XCTAssertNil(topBannerView)
    }

    func test_top_banner_has_two_actions() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refund: nil)
        let stores = createStores(feedbackVisibilityResult: .success(true))
        let factory = ShippingLabelsTopBannerFactory(shippingLabels: [shippingLabel], stores: stores)

        // When
        let topBannerView = try waitFor { promise in
            factory.createTopBannerIfNeeded(isExpanded: false,
                                            onCompletion: { topBannerView in
                                                promise(topBannerView)
                                            })
        }

        // Then
        XCTAssertNotNil(topBannerView)
        let view = try XCTUnwrap(topBannerView)
        let mirrorView = try TopBannerViewMirror(from: view)
        XCTAssertEqual(mirrorView.actionButtons.count, 2)
        mirrorView.actionButtons.first?.sendActions(for: .touchUpInside)
    }

    func test_tapping_top_banner_give_feedback_button_triggers_callback_and_logs_analytics() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refund: nil)
        let stores = createStores(feedbackVisibilityResult: .success(true))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let factory = ShippingLabelsTopBannerFactory(shippingLabels: [shippingLabel], stores: stores, analytics: analytics)

        // When
        var isGiveFeedbackButtonPressed = false
        let topBannerView = try waitFor { promise in
            factory.createTopBannerIfNeeded(isExpanded: false,
                                            onGiveFeedbackButtonPressed: {
                                                isGiveFeedbackButtonPressed = true
                                            },
                                            onCompletion: { topBannerView in
                                                promise(topBannerView)
                                            })
        }

        // Then
        let view = try XCTUnwrap(topBannerView)
        let mirrorView = try TopBannerViewMirror(from: view)
        mirrorView.actionButtons.first?.sendActions(for: .touchUpInside)
        XCTAssertTrue(isGiveFeedbackButtonPressed)

        // Analytics
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, "feature_feedback_banner")
        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch["action"] as? String, "gave_feedback")
        XCTAssertEqual(firstPropertiesBatch["context"] as? String, "shipping_labels_m1")
    }

    func test_tapping_top_banner_dismiss_button_updates_feedback_status_and_triggers_callback_and_logs_analytics() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refund: nil)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(_, onCompletion):
                onCompletion(.success(true))
            case let .updateFeedbackStatus(type, status, onCompletion):
                XCTAssertEqual(type, .shippingLabelsRelease1)
                XCTAssertEqual(status, .dismissed)
                onCompletion(.success(()))
            default:
                break
            }
        }
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let factory = ShippingLabelsTopBannerFactory(shippingLabels: [shippingLabel], stores: stores, analytics: analytics)

        // When
        var isDismissButtonPressed = false
        let topBannerView = try waitFor { promise in
            factory.createTopBannerIfNeeded(isExpanded: false,
                                            onDismissButtonPressed: {
                                                isDismissButtonPressed = true
                                            },
                                            onCompletion: { topBannerView in
                                                promise(topBannerView)
                                            })
        }

        // Then
        let view = try XCTUnwrap(topBannerView)
        let mirrorView = try TopBannerViewMirror(from: view)
        mirrorView.actionButtons[1].sendActions(for: .touchUpInside)
        XCTAssertTrue(isDismissButtonPressed)
        XCTAssertEqual(stores.receivedActions.count, 2)

        // Analytics
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, "feature_feedback_banner")
        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch["action"] as? String, "dismissed")
        XCTAssertEqual(firstPropertiesBatch["context"] as? String, "shipping_labels_m1")
    }
}

private extension ShippingLabelsTopBannerFactoryTests {
    func createStores(feedbackVisibilityResult: Result<Bool, Error>) -> StoresManager {
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(_, onCompletion):
                onCompletion(feedbackVisibilityResult)
            default:
                break
            }
        }
        return stores
    }
}

private extension ShippingLabelsTopBannerFactory {
    func createTopBannerIfNeeded(isExpanded: Bool,
                                 expandedStateChangeHandler: (() -> Void)? = nil,
                                 onGiveFeedbackButtonPressed: (() -> Void)? = nil,
                                 onDismissButtonPressed: (() -> Void)? = nil,
                                 onCompletion: @escaping (TopBannerView?) -> Void) {
        createTopBannerIfNeeded(isExpanded: isExpanded,
                                expandedStateChangeHandler: expandedStateChangeHandler ?? {},
                                onGiveFeedbackButtonPressed: onGiveFeedbackButtonPressed ?? {},
                                onDismissButtonPressed: onDismissButtonPressed ?? {},
                                onCompletion: onCompletion)
    }
}
