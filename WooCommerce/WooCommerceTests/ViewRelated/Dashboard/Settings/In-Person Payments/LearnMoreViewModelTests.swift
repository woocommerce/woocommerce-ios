import Foundation
import Testing
@testable import WooCommerce
import Yosemite

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

}
