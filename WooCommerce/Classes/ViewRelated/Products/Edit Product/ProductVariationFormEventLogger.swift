/// Logs events for actions when editing a product variation.
struct ProductVariationFormEventLogger: ProductFormEventLoggerProtocol {
    func logDescriptionTapped() {
        ServiceLocator.analytics.track(.productVariationDetailViewDescriptionTapped)
    }

    func logImageTapped() {
        ServiceLocator.analytics.track(.productVariationDetailViewImageTapped)
    }

    func logPriceSettingsTapped() {
        ServiceLocator.analytics.track(.productVariationDetailViewPriceSettingsTapped)
    }

    func logInventorySettingsTapped() {
        ServiceLocator.analytics.track(.productVariationDetailViewInventorySettingsTapped)
    }

    func logShippingSettingsTapped() {
        ServiceLocator.analytics.track(.productVariationDetailViewShippingSettingsTapped)
    }

    func logUpdateButtonTapped() {
        ServiceLocator.analytics.track(.productVariationDetailUpdateButtonTapped)
    }

    func logQuantityRulesTapped() {
        ServiceLocator.analytics.track(event: .Variations.quantityRulesTapped())
    }

    func logSubscriptionsTapped() {
        ServiceLocator.analytics.track(event: .Variations.subscriptionsTapped())
    }
}
