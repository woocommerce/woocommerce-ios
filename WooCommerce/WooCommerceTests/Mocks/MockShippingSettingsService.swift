import Foundation
import Yosemite

struct MockShippingSettingsService: ShippingSettingsService {
    var dimensionUnit: String? = "in"

    var weightUnit: String? = "oz"

    func update(siteID: Int64) {
        // no-op
    }
}
