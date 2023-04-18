import XCTest
import Yosemite
@testable import WooCommerce
import WooFoundation

final class ProductSubscription_UITests: XCTestCase {

    private let currencySettings = CurrencySettings()
    private let samplePeriod: SubscriptionPeriod = .month

    func test_priceDescription_returns_expected_description_for_singular_period_interval() {
        // Given
        let subscription = ProductSubscription.fake().copy(period: samplePeriod, periodInterval: "1", price: "5")

        // Then
        XCTAssertEqual(subscription.priceDescription(currencySettings: currencySettings),
                       String.localizedStringWithFormat(Localization.priceFormat, "$5.00", samplePeriod.descriptionSingular))
    }

    func test_priceDescription_returns_expected_description_for_plural_period_interval() {
        // Given
        let subscription = ProductSubscription.fake().copy(period: samplePeriod, periodInterval: "2", price: "5")

        // Then
        XCTAssertEqual(subscription.priceDescription(currencySettings: currencySettings),
                       String.localizedStringWithFormat(Localization.priceFormat, "$5.00", "2 \(samplePeriod.descriptionPlural)"))
    }

    func test_expiryDescription_returns_expected_description_for_singular_subscription_length() {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "1", period: samplePeriod)

        // Then
        XCTAssertEqual(subscription.expiryDescription, "1 \(samplePeriod.descriptionSingular)")
    }

    func test_expiryDescription_returns_expected_description_for_plural_subscription_length() {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "2", period: samplePeriod)

        // Then
        XCTAssertEqual(subscription.expiryDescription, "2 \(samplePeriod.descriptionPlural)")
    }

    func test_expiryDescription_returns_expected_description_for_no_expiry() {
        // Given
        let subscription = ProductSubscription.fake().copy(length: "0", period: samplePeriod)

        // Then
        XCTAssertEqual(subscription.expiryDescription, Localization.neverExpire)
    }

}

private extension ProductSubscription_UITests {
    enum Localization {
        static let priceFormat = NSLocalizedString("%1$@ every %2$@",
                                                   comment: "Description of the subscription price for a product, with the price and billing frequency. " +
                                                   "Reads like: '$60.00 every 2 months'.")
        static let neverExpire = NSLocalizedString("Never expire", comment: "Display label when a subscription never expires.")
    }
}
