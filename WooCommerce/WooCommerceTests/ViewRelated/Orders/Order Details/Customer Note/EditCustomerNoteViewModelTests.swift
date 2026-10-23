import Combine
import XCTest
import TestKit

@testable import WooCommerce
@testable import Yosemite

@MainActor
class EditCustomerNoteViewModelTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    private let order = Order.fake().copy(siteID: 123, orderID: 1234, customerNote: "Original")

    func test_done_button_is_disabled_when_note_content_is_the_same() {
        // Given
        let viewModel = EditCustomerNoteViewModel(order: order)

        // When
        let navigationItem = viewModel.navigationTrailingItem

        // Then
        assertEqual(navigationItem, .done(enabled: false))
    }

    func test_done_button_is_enabled_when_note_content_is_the_different() {
        // Given
        let viewModel = EditCustomerNoteViewModel(order: order)

        // When
        viewModel.newNote = "Edited"

        // Then
        assertEqual(viewModel.navigationTrailingItem, .done(enabled: true))
    }

    func test_view_model_only_updates_customer_note_field() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditCustomerNoteViewModel(order: order, stores: stores)
        viewModel.newNote = "Edited"

        // When
        viewModel.updateNote { _ in }
        let action = try XCTUnwrap(stores.receivedActions.first as? OrderAction)

        // Then
        switch action {
        case let .updateOrderOptimistically(_, order, fields, _),
             let .updateOrder(_, order, _, fields, _, _):
            assertEqual(order.customerNote, "Edited")
            assertEqual(fields, [.customerNote])
        default:
            XCTFail("Unsupported Action")
        }
    }

    func test_view_model_returns_success_after_updating_order_successfully() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isUpdateOrderOptimisticallyOn: false)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditCustomerNoteViewModel(order: order,
                                                 stores: stores,
                                                 noticePresenter: DefaultNoticePresenter(),
                                                 featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, order, _, _, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        let obtainedResult: Bool = try await waitForCompletion { promise in
            viewModel.updateNote(onCompletion: { success in
                promise(success)
            })
        }

        // Then
        XCTAssertTrue(obtainedResult)
    }

    func test_view_model_dispatches_optimistic_order_update_when_feature_flag_is_enabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isUpdateOrderOptimisticallyOn: true)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditCustomerNoteViewModel(order: order, stores: stores, featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderOptimistically(_, order, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        let obtainedResult: Bool = try await waitForCompletion { promise in
            viewModel.updateNote(onCompletion: { success in
                promise(success)
            })
        }

        // Then
        XCTAssertTrue(obtainedResult)
    }

    func test_view_model_dispatches_non_optimistic_order_update_when_feature_flag_is_disabled() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isUpdateOrderOptimisticallyOn: false)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditCustomerNoteViewModel(order: order,
                                                 stores: stores,
                                                 noticePresenter: DefaultNoticePresenter(),
                                                 featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, order, _, _, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        let obtainedResult: Bool = try await waitForCompletion { promise in
            viewModel.updateNote(onCompletion: { success in
                promise(success)
            })
        }

        // Then
        XCTAssertTrue(obtainedResult)
    }

    func test_view_model_does_not_fire_success_notice_after_updating_order_optimistically_successfully() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isUpdateOrderOptimisticallyOn: true)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let noticePresenter = MockNoticePresenter()
        let viewModel = EditCustomerNoteViewModel(order: order,
                                                  stores: stores,
                                                  noticePresenter: noticePresenter,
                                                  featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderOptimistically(_, order, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        try await updateNoteAndWaitForRemoteResult(viewModel)

        // Then
        assertEmpty(noticePresenter.queuedNotices)
    }

    func test_view_model_fires_success_notice_after_updating_order_no_optimistically_successfully() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isUpdateOrderOptimisticallyOn: false)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let noticePresenter = MockNoticePresenter()
        let viewModel = EditCustomerNoteViewModel(order: order,
                                                  stores: stores,
                                                  noticePresenter: noticePresenter,
                                                  featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, order, _, _, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        try await updateNoteAndWaitForRemoteResult(viewModel)

        // Then
        assertEqual(.success, noticePresenter.queuedNotices.first?.feedbackType)
    }

    func test_view_model_fires_error_notice_after_order_update_optimistically_fails_using_default_notice_presenter() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isUpdateOrderOptimisticallyOn: true)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let noticePresenter = MockNoticePresenter()
        let viewModel = EditCustomerNoteViewModel(order: order,
                                                  stores: stores,
                                                  noticePresenter: noticePresenter,
                                                  featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderOptimistically(_, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0, userInfo: nil)))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        try await updateNoteAndWaitForRemoteResult(viewModel)

        // Then
        assertEqual(.error, noticePresenter.queuedNotices.first?.feedbackType)
    }

    func test_view_model_fires_error_notice_after_order_non_optimistic_update_fails_using_modal_notice_presenter() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isUpdateOrderOptimisticallyOn: false)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let noticePresenter = MockNoticePresenter()
        let modalNoticePresenter = MockNoticePresenter()
        let viewModel = EditCustomerNoteViewModel(order: order,
                                                  stores: stores,
                                                  noticePresenter: noticePresenter,
                                                  featureFlagService: featureFlagService)
        viewModel.modalNoticePresenter = modalNoticePresenter
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0, userInfo: nil)))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        try await updateNoteAndWaitForRemoteResult(viewModel)

        // Then
        assertEqual(.error, modalNoticePresenter.queuedNotices.first?.feedbackType)
        assertEmpty(noticePresenter.queuedNotices)
    }

    func test_view_model_returns_no_success_after_order_non_optimistic_update_fails() async throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isUpdateOrderOptimisticallyOn: false)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditCustomerNoteViewModel(order: order, stores: stores, featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0, userInfo: nil)))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        let obtainedResult: Bool = try await waitForCompletion { promise in
            viewModel.updateNote(onCompletion: { success in
                promise(success)
            })
        }

        // Then
        XCTAssertFalse(obtainedResult)
    }

    func test_view_model_tracks_success_after_updating_note() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditCustomerNoteViewModel(order: order, stores: stores, analytics: WooAnalytics(analyticsProvider: analyticsProvider))
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderOptimistically(_, order, _, onCompletion),
                 let .updateOrder(_, order, _, _, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        try await updateNoteAndWaitForRemoteResult(viewModel)

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowCompleted.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "customer_note")
    }

    func test_view_model_tracks_failure_after_failing_to_update_note() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditCustomerNoteViewModel(order: order,
                                                 stores: stores,
                                                 analytics: WooAnalytics(analyticsProvider: analyticsProvider),
                                                 noticePresenter: DefaultNoticePresenter())
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderOptimistically(_, _, _, onCompletion),
                 let .updateOrder(_, _, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0, userInfo: nil)))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        try await updateNoteAndWaitForRemoteResult(viewModel)

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowFailed.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "customer_note")
    }

    func test_view_model_tracks_cancel_flow() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = EditCustomerNoteViewModel(order: order, stores: stores, analytics: WooAnalytics(analyticsProvider: analyticsProvider))

        // When
        viewModel.userDidCancelFlow()

        // Then
        assertEqual(analyticsProvider.receivedEvents, [WooAnalyticsStat.orderDetailEditFlowCanceled.rawValue])
        assertEqual(analyticsProvider.receivedProperties.first?["subject"] as? String, "customer_note")
    }

    func test_view_model_reset_new_note_when_cancel_flow() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditCustomerNoteViewModel(order: order, stores: stores)
        viewModel.newNote = "Edited"

        // When
        viewModel.userDidCancelFlow()

        // Then
        assertEqual(order.customerNote, viewModel.newNote)
    }
}

private extension EditCustomerNoteViewModelTests {
    func updateNoteAndWaitForRemoteResult(_ viewModel: EditCustomerNoteViewModel) async throws {
        let _: Bool = try await waitForCompletion { completion in
            viewModel.$navigationTrailingItem
                .dropFirst(2) // Initial state and request start; the next value follows the remote result.
                .first()
                .sink { _ in completion(true) }
                .store(in: &cancellables)
            viewModel.updateNote(onCompletion: { _ in })
        }
    }
}
