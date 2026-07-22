import Foundation
import Testing
@testable import WooCommerce
import Yosemite
import protocol WooFoundation.Analytics

struct LearnMoreViewModelTests {

    @Test(arguments: [
        (CardPresentPaymentsPlugin.stripe, WooConstants.URLs.inPersonPaymentsLearnMoreStripe.asURL()),
        (CardPresentPaymentsPlugin.wcPay, WooConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL())])
    func learnMore_for_inPersonPayments_uses_correct_link_for_specified_gateway(paymentGateway: CardPresentPaymentsPlugin, learnMoreURL: URL) async throws {
        #expect(LearnMoreViewModel.inPersonPayments(source: .paymentsMenu, paymentGateway: paymentGateway).url == learnMoreURL)
    }

    @Test func learnMore_for_inPersonPayments_uses_correct_formatText() async throws {
        #expect(LearnMoreViewModel.inPersonPayments(
            source: .paymentsMenu,
            paymentGateway: .wcPay).formatText == "%1$@ about In‑Person Payments")
    }

    @Test(arguments: [
        (CardPresentPaymentsPlugin.stripe, WooConstants.URLs.inPersonPaymentsLearnMoreStripe.asURL()),
        (CardPresentPaymentsPlugin.wcPay, WooConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL())])
    func learnMore_for_tapToPay_uses_correct_link_for_specified_gateway(paymentGateway: CardPresentPaymentsPlugin, learnMoreURL: URL) async throws {
        #expect(LearnMoreViewModel.tapToPay(source: .aboutTapToPay, paymentGateway: paymentGateway).url == learnMoreURL)
    }

    @Test func learnMore_for_tapToPay_uses_correct_formatText() async throws {
        #expect(LearnMoreViewModel.tapToPay(
            source: .aboutTapToPay,
            paymentGateway: .wcPay).formatText == "%1$@ about accepting payments with Tap to Pay on iPhone.")
    }

    @Test func learnMoreTapped_when_a_tapped_analytic_event_is_set_then_tracks_the_event() async throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics: Analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = LearnMoreViewModel.inPersonPayments(source: .paymentsMenu, paymentGateway: .wcPay, analytics: analytics)

        // When
        sut.learnMoreTapped()

        // Then
        let eventIndex = try #require(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.inPersonPaymentsLearnMoreTapped.rawValue))
        let properties = analyticsProvider.receivedProperties[eventIndex]
        #expect(properties["source"] as? String == "payments_menu")
    }

    @Test func learnMoreTapped_when_no_tapped_analytic_event_is_set_then_tracks_nothing() async throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics: Analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = LearnMoreViewModel(url: WooConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL(),
                                     tappedAnalyticEvent: nil,
                                     analytics: analytics)

        // When
        sut.learnMoreTapped()

        // Then
        #expect(analyticsProvider.receivedEvents.isEmpty)
    }
}
