import XCTest
import Yosemite
@testable import WooCommerce
import WooFoundation

final class SubscriptionSettingsViewModelTests: XCTestCase {

    private let currencySettings = CurrencySettings()
    private let samplePeriod: SubscriptionPeriod = .month

    func test_priceDescription_returns_expected_description_for_singular_period_interval() {
        // Given
        let subscription = ProductSubscription.fake().copy(period: samplePeriod, periodInterval: "1", price: "5")
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription, currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.priceDescription, String.localizedStringWithFormat(Localization.priceFormat, "$5.00", samplePeriod.descriptionSingular))
    }

    func test_priceDescription_returns_expected_description_for_plural_period_interval() {
        // Given
        let subscription = ProductSubscription.fake().copy(period: samplePeriod, periodInterval: "2", price: "5")
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription, currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.priceDescription, String.localizedStringWithFormat(Localization.priceFormat, "$5.00", "2 \(samplePeriod.descriptionPlural)"))
    }

    func test_priceDescription_returns_expected_description_for_no_price_set() {
        // Given
        let subscription = ProductSubscription.fake().copy(price: "")
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription, currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.priceDescription, Localization.noPrice)
    }

    func test_expiryDescription_returns_expected_description_for_singular_subscription_length() {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "1", period: samplePeriod)
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription)

        // Then
        XCTAssertEqual(viewModel.expiryDescription, "1 \(samplePeriod.descriptionSingular)")
    }

    func test_expiryDescription_returns_expected_description_for_plural_subscription_length() {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "2", period: samplePeriod)
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription)

        // Then
        XCTAssertEqual(viewModel.expiryDescription, "2 \(samplePeriod.descriptionPlural)")
    }

    func test_expiryDescription_returns_expected_description_for_no_expiry() {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "0")
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription)

        // Then
        XCTAssertEqual(viewModel.expiryDescription, Localization.neverExpire)
    }

    func test_signupFeeDescription_returns_formatted_signUpFee() {
        // Given
        let subscription = ProductSubscription.fake().copy(signUpFee: "5")
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription, currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.signupFeeDescription, "$5.00")
    }

    func test_signupFeeDescription_returns_expected_description_for_no_signup_fee() {
        // Given
        let subscription = ProductSubscription.fake().copy(signUpFee: "")
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription, currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.signupFeeDescription, Localization.noSignupFee)
    }

    func test_trialDescription_returns_expected_description_for_singular_trial_length() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "1", trialPeriod: samplePeriod)
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription)

        // Then
        XCTAssertEqual(viewModel.freeTrialDescription, "1 \(samplePeriod.descriptionSingular)")
    }

    func test_trialDescription_returns_expected_description_for_plural_trial_length() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "2", trialPeriod: samplePeriod)
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription)

        // Then
        XCTAssertEqual(viewModel.freeTrialDescription, "2 \(samplePeriod.descriptionPlural)")
    }

    func test_trialDescription_returns_expected_description_for_no_trial() {
        // Given
        let subscription = ProductSubscription.fake().copy(trialLength: "0")
        let viewModel = SubscriptionSettingsViewModel(subscription: subscription)

        // Then
        XCTAssertEqual(viewModel.freeTrialDescription, Localization.noTrial)
    }

}

private extension SubscriptionSettingsViewModelTests {
    enum Localization {
        static let priceFormat = NSLocalizedString("%1$@ every %2$@",
                                                   comment: "Description of the subscription price for a product, with the price and billing frequency. " +
                                                   "Reads like: '$60.00 every 2 months'.")
        static let noPrice = NSLocalizedString("No price set", comment: "Display label when a subscription has no price.")
        static let neverExpire = NSLocalizedString("Never expire", comment: "Display label when a subscription never expires.")
        static let noSignupFee = NSLocalizedString("No signup fee", comment: "Display label when a subscription has no signup fee.")
        static let noTrial = NSLocalizedString("No trial period", comment: "Display label when a subscription has no trial period.")
    }
}
