import XCTest
import TestKit

import YosemiteTestHelpers
@testable import WooCommerce
import Yosemite
import Networking
import protocol WooFoundation.Analytics

final class InPersonPaymentsCashOnDeliveryToggleRowViewModelTests: XCTestCase {
    private var stores: MockStoresManager!

    private var storageManager: MockStorageManager!

    private var noticePresenter: MockNoticePresenter!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private var configuration: CardPresentPaymentsConfiguration!

    private var dependencies: InPersonPaymentsCashOnDeliveryToggleRowViewModel.Dependencies!

    private var sut: InPersonPaymentsCashOnDeliveryToggleRowViewModel!

    private let sampleStoreID: Int64 = 12345

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.sessionManager.setStoreId(sampleStoreID)
        storageManager = MockStorageManager()
        storageManager.insertSamplePaymentGateway(readOnlyGateway: PaymentGateway.fake().copy(siteID: sampleStoreID,
                                                                                              gatewayID: "cod"))
        noticePresenter = MockNoticePresenter()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        configuration = CardPresentPaymentsConfiguration(country: .US)

        dependencies = InPersonPaymentsCashOnDeliveryToggleRowViewModel.Dependencies(
            stores: stores,
            storageManager: storageManager,
            noticePresenter: noticePresenter,
            analytics: analytics
        )
        sut = InPersonPaymentsCashOnDeliveryToggleRowViewModel(dependencies: dependencies,
                                            configuration: configuration)
    }

    /// Builds a view model backed by a fresh storage containing only the given gateway (or none.)
    private func makeSut(gateway: PaymentGateway?) -> InPersonPaymentsCashOnDeliveryToggleRowViewModel {
        let storageManager = MockStorageManager()
        if let gateway {
            storageManager.insertSamplePaymentGateway(readOnlyGateway: gateway)
        }
        let dependencies = InPersonPaymentsCashOnDeliveryToggleRowViewModel.Dependencies(
            stores: stores,
            storageManager: storageManager,
            noticePresenter: noticePresenter,
            analytics: analytics
        )
        return InPersonPaymentsCashOnDeliveryToggleRowViewModel(dependencies: dependencies,
                                                                configuration: configuration)
    }

    // MARK: - Analytics tests
    func test_updateCashOnDeliverySetting_enabled_tracks_paymentsHubCashOnDeliveryToggled_event() throws {
        // Given

        // When
        sut.updateCashOnDeliverySetting(enabled: true)

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == AnalyticEvents.paymentsHubCashOnDeliveryToggled }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        assertEqual("US", eventProperties[AnalyticProperties.countryCodeKey] as? String)
        assertEqual(true, eventProperties[AnalyticProperties.enabledKey] as? Bool)
    }

    func test_updateCashOnDeliverySetting_disabled_tracks_paymentsHubCashOnDeliveryToggled_event() throws {
        // Given

        // When
        sut.updateCashOnDeliverySetting(enabled: false)

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == AnalyticEvents.paymentsHubCashOnDeliveryToggled }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        assertEqual("US", eventProperties[AnalyticProperties.countryCodeKey] as? String)
        assertEqual(false, eventProperties[AnalyticProperties.enabledKey] as? Bool)
    }

    func test_updateCashOnDeliverySetting_enabled_success_logs_enable_success_event() throws {
        // Given
        assertEmpty(analyticsProvider.receivedEvents)
        stores.whenReceivingAction(ofType: PaymentGatewayAction.self) { action in
            switch action {
            case let .updatePaymentGateway(paymentGateway, onCompletion):
                onCompletion(.success(paymentGateway))
            default:
                break
            }
        }

        // When
        sut.updateCashOnDeliverySetting(enabled: true)

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == AnalyticEvents.enableCashOnDeliverySuccess }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        assertEqual("US", eventProperties[AnalyticProperties.countryCodeKey] as? String)
        assertEqual("payments_hub", eventProperties[AnalyticProperties.sourceKey] as? String)
    }

    func test_updateCashOnDeliverySetting_enabled_failure_logs_enable_failure_event() throws {
        // Given
        stores.whenReceivingAction(ofType: PaymentGatewayAction.self) { action in
            switch action {
            case let .updatePaymentGateway(_, onCompletion):
                onCompletion(.failure(DotcomError.noRestRoute()))
            default:
                break
            }
        }

        // When
        sut.updateCashOnDeliverySetting(enabled: true)

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == AnalyticEvents.enableCashOnDeliveryFailed }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        assertEqual("US", eventProperties[AnalyticProperties.countryCodeKey] as? String)
        assertEqual("Dotcom Invalid REST Route", eventProperties[AnalyticProperties.errorDescriptionKey] as? String)
        assertEqual("payments_hub", eventProperties[AnalyticProperties.sourceKey] as? String)
    }

    func test_updateCashOnDeliverySetting_disabled_success_logs_disable_success_event() throws {
        // Given
        assertEmpty(analyticsProvider.receivedEvents)
        stores.whenReceivingAction(ofType: PaymentGatewayAction.self) { action in
            switch action {
            case let .updatePaymentGateway(paymentGateway, onCompletion):
                onCompletion(.success(paymentGateway))
            default:
                break
            }
        }

        // When
        sut.updateCashOnDeliverySetting(enabled: false)

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == AnalyticEvents.disableCashOnDeliverySuccess }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        assertEqual("US", eventProperties[AnalyticProperties.countryCodeKey] as? String)
        assertEqual("payments_hub", eventProperties[AnalyticProperties.sourceKey] as? String)
    }

    func test_updateCashOnDeliverySetting_disabled_failure_logs_disable_failure_event() throws {
        // Given
        stores.whenReceivingAction(ofType: PaymentGatewayAction.self) { action in
            switch action {
            case let .updatePaymentGateway(_, onCompletion):
                onCompletion(.failure(DotcomError.noRestRoute()))
            default:
                break
            }
        }

        // When
        sut.updateCashOnDeliverySetting(enabled: false)

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == AnalyticEvents.disableCashOnDeliveryFailed }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        assertEqual("US", eventProperties[AnalyticProperties.countryCodeKey] as? String)
        assertEqual("Dotcom Invalid REST Route", eventProperties[AnalyticProperties.errorDescriptionKey] as? String)
        assertEqual("payments_hub", eventProperties[AnalyticProperties.sourceKey] as? String)
    }

    // MARK: - Toggle confirmation tests
    func test_cashOnDeliveryToggleRequested_then_nothing_changes_before_the_user_confirms() {
        // Given
        assertEmpty(analyticsProvider.receivedEvents)

        // When
        sut.cashOnDeliveryToggleRequested(enabled: true)

        // Then
        assertEmpty(stores.receivedActions)
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(AnalyticEvents.paymentsHubCashOnDeliveryToggled))
        XCTAssertFalse(sut.cashOnDeliveryEnabledState)
        XCTAssertNotNil(sut.pendingToggleConfirmation)
    }

    func test_cashOnDeliveryToggleRequested_enabled_when_gateway_has_custom_title_then_confirmation_warns_about_rename() throws {
        // Given
        let sut = makeSut(gateway: PaymentGateway.fake().copy(siteID: sampleStoreID,
                                                              gatewayID: "cod",
                                                              title: "Cash on delivery"))

        // When
        sut.cashOnDeliveryToggleRequested(enabled: true)

        // Then
        let confirmation = try XCTUnwrap(sut.pendingToggleConfirmation)
        assertEqual("Enable Pay In Person?", confirmation.title)
        XCTAssertTrue(confirmation.message.contains("renames it from “Cash on delivery” to “Pay in Person”"))
        assertEqual("Enable", confirmation.confirmButtonTitle)
        assertEqual("Cancel", confirmation.cancelButtonTitle)
        XCTAssertTrue(confirmation.targetState)
    }

    func test_cashOnDeliveryToggleRequested_enabled_when_title_is_already_pay_in_person_then_confirmation_omits_rename() throws {
        // Given
        let sut = makeSut(gateway: PaymentGateway.fake().copy(siteID: sampleStoreID,
                                                              gatewayID: "cod",
                                                              title: "PAY IN PERSON"))

        // When
        sut.cashOnDeliveryToggleRequested(enabled: true)

        // Then
        let confirmation = try XCTUnwrap(sut.pendingToggleConfirmation)
        XCTAssertFalse(confirmation.message.contains("renames"))
    }

    func test_cashOnDeliveryToggleRequested_enabled_when_no_gateway_stored_then_confirmation_omits_rename() throws {
        // Given
        let sut = makeSut(gateway: nil)

        // When
        sut.cashOnDeliveryToggleRequested(enabled: true)

        // Then
        let confirmation = try XCTUnwrap(sut.pendingToggleConfirmation)
        XCTAssertFalse(confirmation.message.contains("renames"))
    }

    func test_cashOnDeliveryToggleRequested_disabled_then_confirmation_warns_about_disabling_at_checkout() throws {
        // When
        sut.cashOnDeliveryToggleRequested(enabled: false)

        // Then
        let confirmation = try XCTUnwrap(sut.pendingToggleConfirmation)
        assertEqual("Disable Pay In Person?", confirmation.title)
        assertEqual("This disables the Cash on Delivery payment method at your store’s checkout, " +
                    "so customers won’t be able to select it.", confirmation.message)
        assertEqual("Disable", confirmation.confirmButtonTitle)
        assertEqual("Cancel", confirmation.cancelButtonTitle)
        XCTAssertFalse(confirmation.targetState)
    }

    func test_confirmCashOnDeliveryToggle_tracks_toggled_event_and_dispatches_the_gateway_update() throws {
        // Given
        sut.cashOnDeliveryToggleRequested(enabled: true)

        // When
        sut.confirmCashOnDeliveryToggle()

        // Then
        XCTAssertNil(sut.pendingToggleConfirmation)
        XCTAssertTrue(sut.cashOnDeliveryEnabledState)
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(AnalyticEvents.paymentsHubCashOnDeliveryToggled))
        let action = try XCTUnwrap(stores.receivedActions.compactMap { $0 as? PaymentGatewayAction }.first)
        guard case .updatePaymentGateway(let gateway, _) = action else {
            return XCTFail("Expected updatePaymentGateway, got \(action)")
        }
        XCTAssertTrue(gateway.enabled)
    }

    func test_confirmCashOnDeliveryToggle_when_no_confirmation_is_pending_then_nothing_happens() {
        // When
        sut.confirmCashOnDeliveryToggle()

        // Then
        XCTAssertFalse(sut.cashOnDeliveryEnabledState)
        assertEmpty(stores.receivedActions)
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(AnalyticEvents.paymentsHubCashOnDeliveryToggled))
    }

    func test_dismissCashOnDeliveryToggleConfirmation_then_the_gateway_is_left_untouched() {
        // Given
        sut.cashOnDeliveryToggleRequested(enabled: true)

        // When
        sut.dismissCashOnDeliveryToggleConfirmation()

        // Then
        XCTAssertNil(sut.pendingToggleConfirmation)
        XCTAssertFalse(sut.cashOnDeliveryEnabledState)
        assertEmpty(stores.receivedActions)
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(AnalyticEvents.paymentsHubCashOnDeliveryToggled))
    }

    func test_learnMoreTapped_tracks_paymentsHubCashOnDeliveryToggleLearnMoreTapped_event() throws {
        // Given

        // When
        sut.learnMoreTapped(from: UIViewController())

        // Then
        let event = try XCTUnwrap(analyticsProvider.receivedEvents.first(where: { $0 == AnalyticEvents.paymentsHubCashOnDeliveryToggleLearnMoreTapped } ))
        XCTAssertNotNil(event)
    }
}

private enum AnalyticEvents {
    static let enableCashOnDeliverySuccess = "enable_cash_on_delivery_success"
    static let enableCashOnDeliveryFailed = "enable_cash_on_delivery_failed"
    static let disableCashOnDeliverySuccess = "disable_cash_on_delivery_success"
    static let disableCashOnDeliveryFailed = "disable_cash_on_delivery_failed"
    static let paymentsHubCashOnDeliveryToggled = "payments_hub_cash_on_delivery_toggled"
    static let paymentsHubCashOnDeliveryToggleLearnMoreTapped = "payments_hub_cash_on_delivery_toggle_learn_more_tapped"
}

private enum AnalyticProperties {
    static let countryCodeKey = "country"
    static let errorDescriptionKey = "error_description"
    static let sourceKey = "source"
    static let enabledKey = "enabled"
}
