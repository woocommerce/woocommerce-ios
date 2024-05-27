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

    func logSubscriptionsFreeTrialTapped() {
        ServiceLocator.analytics.track(event: .Variations.freeTrialSettingsTapped())
    }

    func logSubscriptionsExpirationDateTapped() {
        ServiceLocator.analytics.track(event: .Variations.expirationDateSettingsTapped())
    }

    func logQuantityRulesDoneButtonTapped(hasUnsavedChanges: Bool) {
        ServiceLocator.analytics.track(event: .Variations.quantityRulesDoneButtonTapped(hasChangedData: hasUnsavedChanges))
    }
}
