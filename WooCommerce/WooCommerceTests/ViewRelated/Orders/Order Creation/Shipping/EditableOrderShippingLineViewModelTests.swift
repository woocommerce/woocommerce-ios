import XCTest
import WooFoundation
import Yosemite
import Storage
@testable import WooCommerce

final class EditableOrderShippingLineViewModelTests: XCTestCase {
    var viewModel: EditableOrderShippingLineViewModel!
    var stores: MockStoresManager!
    var storageManager: MockStorageManager!
    var analytics: MockAnalyticsProvider!
    var orderSynchronizer: RemoteOrderSynchronizer!

    let sampleSiteID: Int64 = 123
    let sampleOrderID: Int64 = 1234
    let sampleProductID: Int64 = 5
    let currencySettings = CurrencySettings()

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        storageManager = MockStorageManager()
        analytics = MockAnalyticsProvider()
        orderSynchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores, currencySettings: currencySettings)
        viewModel = EditableOrderShippingLineViewModel(siteID: sampleSiteID,
                                                   flow: .creation,
                                                   orderSynchronizer: orderSynchronizer,
                                                   analytics: WooAnalytics(analyticsProvider: analytics),
                                                   storageManager: storageManager,
                                                   stores: stores,
                                                   currencySettings: currencySettings)
    }

    // MARK: Initialization

    func test_init_syncs_available_shipping_methods() {
        // Given
        var shippingMethodsSynced = false
        stores.whenReceivingAction(ofType: ShippingMethodAction.self) { action in
            switch action {
            case let .synchronizeShippingMethods(_, completion):
                shippingMethodsSynced = true
                completion(.success(()))
            }
        }

        // When
        _ = EditableOrderShippingLineViewModel(siteID: sampleSiteID,
                                             flow: .creation,
                                             orderSynchronizer: orderSynchronizer,
                                             stores: stores)

        // Then
        XCTAssertTrue(shippingMethodsSynced)
    }

    func test_use_case_inits_with_expected_shipping_line_row_from_order_shipping_line_and_stored_shipping_method() throws {
        // Given
        let shippingMethod = ShippingMethod(siteID: sampleSiteID, methodID: "flat_rate", title: "Flat Rate")
        storageManager.insert(shippingMethod)
        let shippingLine = ShippingLine.fake().copy(methodTitle: "Package 1", methodID: "flat_rate")
        let order = Order.fake().copy(siteID: sampleSiteID, shippingLines: [shippingLine])

        // When
        let viewModel = EditableOrderShippingLineViewModel(siteID: sampleSiteID,
                                                       flow: .editing(initialOrder: order),
                                                       orderSynchronizer: RemoteOrderSynchronizer(siteID: sampleSiteID,
                                                                                                  flow: .editing(initialOrder: order),
                                                                                                  stores: stores),
                                                       storageManager: storageManager)

        // Then
        assertEqual(1, viewModel.shippingLineRows.count)
        let shippingLineRow = try XCTUnwrap(viewModel.shippingLineRows.first)
        assertEqual(shippingLine.methodTitle, shippingLineRow.shippingTitle)
        assertEqual(shippingMethod.title, shippingLineRow.shippingMethod)
    }

    // MARK: Payment data

    func test_payment_data_is_initialized_with_expected_values() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)

        // When
        let paymentData = EditableOrderShippingLineViewModel.ShippingPaymentData(shippingTotal: "3.00",
                                                                               shippingTax: "0.30",
                                                                               currencyFormatter: CurrencyFormatter(currencySettings: currencySettings))

        // Then
        XCTAssertEqual(paymentData.shippingTotal, "£3.00")
        XCTAssertEqual(paymentData.shippingTax, "£0.30")
        XCTAssertTrue(paymentData.shouldShowShippingTax)
    }

    func test_payment_data_is_initialized_with_expected_default_values_for_new_order() {
        // Given
        let paymentData = viewModel.paymentData

        // Then
        XCTAssertEqual(paymentData.shippingTotal, "$0.00")
        XCTAssertEqual(paymentData.shippingTax, "$0.00")
        XCTAssertFalse(paymentData.shouldShowShippingTax)
    }

    func test_payment_data_is_updated_when_shipping_line_updated() throws {
        // When
        let shippingLine = ShippingLine(shippingID: 0,
                                        methodTitle: "Flat Rate",
                                        methodID: "other",
                                        total: "10",
                                        totalTax: "",
                                        taxes: [])
        viewModel.saveShippingLine(shippingLine)

        // Then
        XCTAssertTrue(viewModel.paymentData.shouldShowShippingTotal)
        XCTAssertEqual(viewModel.paymentData.shippingTotal, "$10.00")

        // When
        viewModel.removeShippingLine(shippingLine)

        // Then
        XCTAssertFalse(viewModel.paymentData.shouldShowShippingTotal)
        XCTAssertEqual(viewModel.paymentData.shippingTotal, "$0.00")
    }

    func test_payment_data_values_correct_when_shipping_line_is_negative() throws {
        // When
        let shippingLine = ShippingLine(shippingID: 0,
                                        methodTitle: "Flat Rate",
                                        methodID: "other",
                                        total: "-5",
                                        totalTax: "",
                                        taxes: [])
        viewModel.saveShippingLine(shippingLine)

        // Then
        XCTAssertTrue(viewModel.paymentData.shouldShowShippingTotal)
        XCTAssertEqual(viewModel.paymentData.shippingTotal, "-$5.00")

        // When
        viewModel.removeShippingLine(shippingLine)

        // Then
        XCTAssertFalse(viewModel.paymentData.shouldShowShippingTotal)
        XCTAssertEqual(viewModel.paymentData.shippingTotal, "$0.00")
    }

    // MARK: Add shipping line

    func test_addShippingLine_sets_view_model_for_new_shipping_line() throws {
        // When
        viewModel.addShippingLine()

        // Then
        let detailsViewModel = try XCTUnwrap(viewModel.shippingLineDetails)
        XCTAssertFalse(detailsViewModel.isExistingShippingLine)
    }

    // MARK: Shipping line rows

    func test_saveShippingLine_updates_shipping_line_rows() {
        // Given
        let shippingLine = ShippingLine.fake().copy(methodTitle: "Flat Rate")

        // When
        viewModel.saveShippingLine(shippingLine)

        // Then
        assertEqual(1, viewModel.shippingLineRows.count)
        assertEqual(shippingLine.methodTitle, viewModel.shippingLineRows.first?.shippingTitle)
    }

    func test_expected_view_model_set_when_shipping_line_row_is_edited() throws {
        // Given
        let shippingLine = ShippingLine.fake().copy(methodTitle: "Flat Rate")
        let order = Order.fake().copy(siteID: sampleSiteID, shippingLines: [shippingLine])
        let viewModel = EditableOrderShippingLineViewModel(siteID: sampleSiteID,
                                                       flow: .editing(initialOrder: order),
                                                       orderSynchronizer: RemoteOrderSynchronizer(siteID: sampleSiteID,
                                                                                                  flow: .editing(initialOrder: order),
                                                                                                  stores: stores))

        // When
        viewModel.shippingLineRows.first?.editShippingLine()

        // Then
        let detailsViewModel = try XCTUnwrap(viewModel.shippingLineDetails)
        XCTAssertTrue(detailsViewModel.isExistingShippingLine)
        assertEqual(shippingLine.methodTitle, detailsViewModel.methodTitle)
    }

    func test_shipping_line_row_is_editable_for_new_order() throws {
        // Given
        XCTAssertFalse(viewModel.shouldShowNonEditableIndicators)
        let shippingLine = ShippingLine.fake().copy(methodTitle: "Flat Rate")

        // When
        viewModel.saveShippingLine(shippingLine)

        // Then
        let shippingLineRow = try XCTUnwrap(viewModel.shippingLineRows.first)
        XCTAssertTrue(shippingLineRow.editable)
    }

    func test_shipping_line_row_is_not_editable_for_a_non_editable_order() throws {
        // Given
        let shippingLine = ShippingLine.fake().copy(methodTitle: "Flat Rate")
        let order = Order.fake().copy(siteID: sampleSiteID, isEditable: false, shippingLines: [shippingLine])

        // When
        let viewModel = EditableOrderShippingLineViewModel(siteID: sampleSiteID,
                                                       flow: .editing(initialOrder: order),
                                                       orderSynchronizer: RemoteOrderSynchronizer(siteID: sampleSiteID,
                                                                                                  flow: .editing(initialOrder: order),
                                                                                                  stores: stores))

        // Then
        let shippingLineRow = try XCTUnwrap(viewModel.shippingLineRows.first)
        XCTAssertFalse(shippingLineRow.editable)
    }

    func test_shipping_line_row_is_editable_for_an_editable_order() throws {
        // Given
        let shippingLine = ShippingLine.fake().copy(methodTitle: "Flat Rate")
        let order = Order.fake().copy(siteID: sampleSiteID, isEditable: true, shippingLines: [shippingLine])

        // When
        let viewModel = EditableOrderShippingLineViewModel(siteID: sampleSiteID,
                                                       flow: .editing(initialOrder: order),
                                                       orderSynchronizer: RemoteOrderSynchronizer(siteID: sampleSiteID,
                                                                                                  flow: .editing(initialOrder: order),
                                                                                                  stores: stores))

        // Then
        let shippingLineRow = try XCTUnwrap(viewModel.shippingLineRows.first)
        XCTAssertTrue(shippingLineRow.editable)
    }

    func test_shipping_line_row_is_not_editable_for_order() throws {
        // Given
        XCTAssertFalse(viewModel.shouldShowNonEditableIndicators)
        let shippingLine = ShippingLine.fake().copy(methodTitle: "Flat Rate")

        // When
        viewModel.saveShippingLine(shippingLine)

        // Then
        let shippingLineRow = try XCTUnwrap(viewModel.shippingLineRows.first)
        XCTAssertTrue(shippingLineRow.editable)
    }

    // MARK: Analytics

    func test_addShippingLine_tracks_expected_event() {
        // When
        viewModel.addShippingLine()

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderAddShippingTapped.rawValue])
    }

    func test_saveShippingLine_tracks_expected_event_and_properties() throws {
        // Given
        let shippingLine = ShippingLine.fake().copy(methodID: "flat_rate")

        // When
        viewModel.saveShippingLine(shippingLine)

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderShippingMethodAdd.rawValue])
        assertEqual("creation", analytics.receivedProperties.first?["flow"] as? String)
        assertEqual("flat_rate", analytics.receivedProperties.first?["shipping_method"] as? String)
        assertEqual(1, analytics.receivedProperties.first?["shipping_lines_count"] as? Int64)
    }

    func test_removeShippingLine_tracks_expected_event() throws {
        // When
        viewModel.removeShippingLine(ShippingLine.fake())

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderShippingMethodRemove.rawValue])

        let properties = try XCTUnwrap(analytics.receivedProperties.first?["flow"] as? String)
        XCTAssertEqual(properties, "creation")
    }

    // MARK: Feedback survey

    func test_feedback_survey_config_has_expected_feedback_type() throws {
        // Given
        let expectedFeedbackType: SurveyViewController.Source = .orderFormShippingLines

        // When & Then
        assertEqual(expectedFeedbackType, viewModel.feedbackBannerConfig.feedbackType)
    }

    func test_feedback_survey_config_onSurveyButtonTapped_updates_feedback_visibility() throws {
        // Given
        var updatedType: FeedbackType?
        var updatedStatus: FeedbackSettings.Status?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .updateFeedbackStatus(type, status, onCompletion):
                updatedType = type
                updatedStatus = status
                onCompletion(.success(()))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        viewModel.feedbackBannerConfig.onSurveyButtonTapped()

        // Then
        assertEqual(.orderFormShippingLines, updatedType)
        switch updatedStatus {
        case .given:
            break
        default:
            XCTFail("Unexpected feedback status received: \(String(describing: updatedStatus))")
        }
    }

    func test_feedback_survey_config_onSurveyButtonTapped_tracks_expected_event() throws {
        // When
        viewModel.feedbackBannerConfig.onSurveyButtonTapped()

        // Then
        assertEqual([WooAnalyticsStat.featureFeedbackBanner.rawValue], analytics.receivedEvents)
        assertEqual("order_form_shipping_lines", analytics.receivedProperties.first?["context"] as? String)
        assertEqual("gave_feedback", analytics.receivedProperties.first?["action"] as? String)
    }

    func test_feedback_survey_config_onCloseButtonTapped_updates_feedback_visibility() throws {
        // Given
        var updatedType: FeedbackType?
        var updatedStatus: FeedbackSettings.Status?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .updateFeedbackStatus(type, status, onCompletion):
                updatedType = type
                updatedStatus = status
                onCompletion(.success(()))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        viewModel.feedbackBannerConfig.onCloseButtonTapped()

        // Then
        assertEqual(.orderFormShippingLines, updatedType)
        assertEqual(.dismissed, updatedStatus)
    }

    func test_feedback_survey_config_onCloseButtonTapped_tracks_expected_event() throws {
        // When
        viewModel.feedbackBannerConfig.onCloseButtonTapped()

        // Then
        assertEqual([WooAnalyticsStat.featureFeedbackBanner.rawValue], analytics.receivedEvents)
        assertEqual("order_form_shipping_lines", analytics.receivedProperties.first?["context"] as? String)
        assertEqual("dismissed", analytics.receivedProperties.first?["action"] as? String)
    }
}

private extension MockStorageManager {
    func insert(_ readOnlyShippingMethod: Yosemite.ShippingMethod) {
        let shippingMethod = viewStorage.insertNewObject(ofType: StorageShippingMethod.self)
        shippingMethod.update(with: readOnlyShippingMethod)
        viewStorage.saveIfNeeded()
    }
}
