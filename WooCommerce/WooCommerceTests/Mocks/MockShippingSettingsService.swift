import Yosemite

struct MockShippingSettingsService: ShippingSettingsService {
    var dimensionUnit: String?
    var weightUnit: String?

    init(dimensionUnit: String?, weightUnit: String?) {
        self.dimensionUnit = dimensionUnit
        self.weightUnit = weightUnit
    }

    func update(siteID: Int64) {
        // No-op
    }
}
