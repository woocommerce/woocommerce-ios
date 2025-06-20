public protocol ShippingSettingsService {
    var dimensionUnit: String? { get }
    var weightUnit: String? { get }

    /// Called when the site ID changes.
    ///
    func update(siteID: Int64)
}
