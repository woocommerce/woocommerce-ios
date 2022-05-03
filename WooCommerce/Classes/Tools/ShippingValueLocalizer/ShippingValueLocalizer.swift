/// Localizes and unlocalizes the shipping values such as weight and package dimensions (non-currency values)
///
/// - Localizes shipping value from API locale to device locale.
/// - Unlocalizes shipping value from device locale to API preferred locale.
///
/// API does not accept shipping values with comma as decimal separator. More details at p91TBi-8kO-p2
///
protocol ShippingValueLocalizer {
    /// Localizes the `shippingValue`
    ///
    func localized(shippingValue: String?) -> String?

    /// Unlocalizes the `shippingValue`
    ///
    func unLocalized(shippingValue: String?) -> String?
}
