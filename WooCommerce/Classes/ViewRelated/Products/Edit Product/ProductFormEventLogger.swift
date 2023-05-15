/// Logs events for actions when editing a product.
struct ProductFormEventLogger: ProductFormEventLoggerProtocol {
    func logDescriptionTapped() {
        ServiceLocator.analytics.track(.productDetailViewProductDescriptionTapped)
    }

    func logImageTapped() {
        ServiceLocator.analytics.track(.productDetailAddImageTapped)
    }

    func logPriceSettingsTapped() {
        ServiceLocator.analytics.track(.productDetailViewPriceSettingsTapped)
    }

    func logInventorySettingsTapped() {
        ServiceLocator.analytics.track(.productDetailViewInventorySettingsTapped)
    }

    func logShippingSettingsTapped() {
        ServiceLocator.analytics.track(.productDetailViewShippingSettingsTapped)
    }

    func logUpdateButtonTapped() {
        ServiceLocator.analytics.track(.productDetailUpdateButtonTapped)
    }

    func logQuantityRulesTapped() {
        ServiceLocator.analytics.track(event: .ProductDetail.quantityRulesTapped())
    }

    func logSubscriptionsTapped() {
        ServiceLocator.analytics.track(event: .ProductDetail.subscriptionsTapped())
    }
}
