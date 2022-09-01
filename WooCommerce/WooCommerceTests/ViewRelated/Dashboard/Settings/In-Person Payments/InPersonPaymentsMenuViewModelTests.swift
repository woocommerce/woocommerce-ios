import XCTest
import TestKit

@testable import WooCommerce
import Yosemite
import Networking

final class InPersonPaymentsMenuViewModelTests: XCTestCase {
    private var stores: MockStoresManager!

    private var noticePresenter: MockNoticePresenter!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private var configuration: CardPresentPaymentsConfiguration!

    private var dependencies: InPersonPaymentsMenuViewModel.Dependencies!

    private var sut: InPersonPaymentsMenuViewModel!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.sessionManager.setStoreId(12345)
        noticePresenter = MockNoticePresenter()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        configuration = CardPresentPaymentsConfiguration.init(country: "US")
        dependencies = InPersonPaymentsMenuViewModel.Dependencies(
            stores: stores,
            noticePresenter: noticePresenter,
            analytics: analytics
        )
        sut = InPersonPaymentsMenuViewModel(dependencies: dependencies,
                                            configuration: configuration)
    }

    // MARK: - Analytics tests
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
}

private enum AnalyticEvents {
    static let enableCashOnDeliverySuccess = "enable_cash_on_delivery_success"
    static let enableCashOnDeliveryFailed = "enable_cash_on_delivery_failed"
}

private enum AnalyticProperties {
    static let countryCodeKey = "country"
    static let errorDescriptionKey = "error_description"
    static let sourceKey = "source"
}
