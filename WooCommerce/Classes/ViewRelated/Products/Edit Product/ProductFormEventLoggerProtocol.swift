/// Contains common logging actions that might differ in implementation.
protocol ProductFormEventLoggerProtocol {
    /// Called to log an event when the description row is tapped.
    func logDescriptionTapped()

    /// Called to log an event when an image or Add Image CTA is tapped.
    func logImageTapped()

    /// Called to log an event when the price settings row is tapped.
    func logPriceSettingsTapped()

    /// Called to log an event when the inventory settings row is tapped.
    func logInventorySettingsTapped()

    /// Called to log an event when the shipping settings row is tapped.
    func logShippingSettingsTapped()

    /// Called to log an event when the update CTA is tapped.
    func logUpdateButtonTapped()

    /// Called to log an event when the quantity rules row is tapped.
    func logQuantityRulesTapped()
}
