import XCTest
import TestKit

@testable import WooCommerce
import Yosemite
import Networking

final class InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModelTests: XCTestCase {
    private var stores: MockStoresManager!

    private var noticePresenter: MockNoticePresenter!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private var configuration: CardPresentPaymentsConfiguration!

    private var dependencies: InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel.Dependencies!

    private var sut: InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.sessionManager.setStoreId(12345)
        noticePresenter = MockNoticePresenter()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        configuration = CardPresentPaymentsConfiguration.init(country: "US")
        dependencies = InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel.Dependencies(
            stores: stores,
            noticePresenter: noticePresenter,
            analytics: analytics
        )
        sut = InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel(
            dependencies: dependencies,
            configuration: configuration,
            plugin: .wcPay,
            analyticReason: AnalyticProperties.cashOnDeliveryDisabledReason,
            completion: {})
    }

    func test_skip_always_calls_completion() {
        // Given
        let completionCalled: Bool = waitFor { promise in
            let sut = InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel(
                dependencies: self.dependencies,
                configuration: self.configuration,
                plugin: .wcPay,
                analyticReason: AnalyticProperties.cashOnDeliveryDisabledReason,
                completion: {
                    promise(true)
                })

            // When
            sut.skipTapped()
        }

        // Then
        XCTAssert(completionCalled)
    }

    func test_skip_saves_skipped_preference_for_the_current_site() {
        // Given
        var spySavedOnboardingSkipForSiteID: Int64? = nil
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .setSkippedCashOnDeliveryOnboardingStep(siteID):
                spySavedOnboardingSkipForSiteID = siteID
            default:
                break
            }
        }

        // When
        sut.skipTapped()

        // Then
        XCTAssertNotNil(spySavedOnboardingSkipForSiteID)
        assertEqual(12345, spySavedOnboardingSkipForSiteID)
    }

    func test_enable_success_calls_completion() {
        // Given
        stores.whenReceivingAction(ofType: PaymentGatewayAction.self) { action in
            switch action {
            case let .updatePaymentGateway(paymentGateway, onCompletion):
                onCompletion(.success(paymentGateway))
            default:
                break
            }
        }

        let completionCalled: Bool = waitFor { promise in
            let sut = InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel(
                dependencies: self.dependencies,
                configuration: self.configuration,
                plugin: .wcPay,
                analyticReason: AnalyticProperties.cashOnDeliveryDisabledReason,
                completion: {
                    promise(true)
                })
            // When
            sut.enableTapped()
        }

        // Then
        XCTAssert(completionCalled)
    }

    func test_enable_failure_displays_notice() throws {
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
        sut.enableTapped()

        // Then
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        let expectedTitle = "Failed to enable Pay in Person. Please try again later."
        assertEqual(expectedTitle, notice.title)
    }

    // MARK: - Analytics tests
    func test_skip_tapped_logs_onboarding_step_skipped_event() throws {
        // Given
        assertEmpty(analyticsProvider.receivedEvents)

        // When
        sut.skipTapped()

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == AnalyticEvents.skippedEvent }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        assertEqual(AnalyticProperties.cashOnDeliveryDisabledReason, eventProperties[AnalyticProperties.reasonKey] as? String)
        assertEqual(false, eventProperties[AnalyticProperties.remindLaterKey] as? Bool)
        assertEqual("US", eventProperties[AnalyticProperties.countryCodeKey] as? String)
    }

    func test_enable_tapped_logs_cta_tapped_event() throws {
        // Given
        assertEmpty(analyticsProvider.receivedEvents)

        // When
        sut.enableTapped()

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == AnalyticEvents.ctaTappedEvent }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        assertEqual(AnalyticProperties.cashOnDeliveryDisabledReason, eventProperties[AnalyticProperties.reasonKey] as? String)
        assertEqual("US", eventProperties[AnalyticProperties.countryCodeKey] as? String)
    }

    func test_enable_success_logs_enable_success_event() throws {
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

        let _: Void = waitFor { promise in
            let sut = InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel(
                dependencies: self.dependencies,
                configuration: self.configuration,
                plugin: .wcPay,
                analyticReason: AnalyticProperties.cashOnDeliveryDisabledReason,
                completion: {
                promise(())
            })
            // When
            sut.enableTapped()
        }

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == AnalyticEvents.enableCashOnDeliverySuccess }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        assertEqual("US", eventProperties[AnalyticProperties.countryCodeKey] as? String)
        assertEqual("onboarding", eventProperties[AnalyticProperties.sourceKey] as? String)
    }

    func test_enable_failure_logs_enable_failure_event() throws {
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
        sut.enableTapped()

        // Then
        assertNotEmpty(analyticsProvider.receivedEvents)
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == AnalyticEvents.enableCashOnDeliveryFailed }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        assertEqual("US", eventProperties[AnalyticProperties.countryCodeKey] as? String)
        assertEqual("Dotcom Invalid REST Route", eventProperties[AnalyticProperties.errorDescriptionKey] as? String)
        assertEqual("onboarding", eventProperties[AnalyticProperties.sourceKey] as? String)
    }
}

private enum AnalyticEvents {
    static let skippedEvent = "card_present_onboarding_step_skipped"
    static let ctaTappedEvent = "card_present_onboarding_cta_tapped"
    static let enableCashOnDeliverySuccess = "enable_cash_on_delivery_success"
    static let enableCashOnDeliveryFailed = "enable_cash_on_delivery_failed"
}

private enum AnalyticProperties {
    static let reasonKey = "reason"
    static let cashOnDeliveryDisabledReason = "cash_on_delivery_disabled"
    static let remindLaterKey = "remind_later"
    static let countryCodeKey = "country"
    static let errorDescriptionKey = "error_description"
    static let sourceKey = "source"
}
