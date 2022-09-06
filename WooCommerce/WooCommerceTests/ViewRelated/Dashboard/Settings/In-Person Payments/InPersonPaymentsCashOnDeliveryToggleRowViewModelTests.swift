import XCTest
import TestKit

@testable import WooCommerce
import Yosemite
import Networking

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
        configuration = CardPresentPaymentsConfiguration.init(country: "US")

        dependencies = InPersonPaymentsCashOnDeliveryToggleRowViewModel.Dependencies(
            stores: stores,
            storageManager: storageManager,
            noticePresenter: noticePresenter,
            analytics: analytics
        )
        sut = InPersonPaymentsCashOnDeliveryToggleRowViewModel(dependencies: dependencies,
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
                onCompletion(.failure(DotcomError.noRestRoute))
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
                onCompletion(.failure(DotcomError.noRestRoute))
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
