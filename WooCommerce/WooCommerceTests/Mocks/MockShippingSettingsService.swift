import Foundation
import Yosemite

struct MockShippingSettingsService: ShippingSettingsService {
    var dimensionUnit: String?

    var weightUnit: String?

    init(dimensionUnit: String? = "in", weightUnit: String? = "oz") {
        self.dimensionUnit = dimensionUnit
        self.weightUnit = weightUnit
    }

    func update(siteID: Int64) {
        // no-op
    }
}
