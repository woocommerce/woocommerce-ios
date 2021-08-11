import Foundation
import Yosemite

final class ShippingLabelCustomsFormItemDetailsViewModel {
    /// Description for the item.
    ///
    @Published var description: String

    /// Price of item per unit.
    ///
    @Published var value: Double

    /// Weight of item per unit.
    ///
    @Published var weight: Double

    /// HS tariff number, empty if N/A.
    ///
    @Published var hsTariffNumber: String

    /// Origin country code of item.
    ///
    @Published var originCountry: String

    /// Validated item if all fields are valid.
    ///
    private(set) var validatedItem: ShippingLabelCustomsForm.Item?

    init(item: ShippingLabelCustomsForm.Item) {
        self.description = item.description
        self.value = item.value
        self.weight = item.weight
        self.hsTariffNumber = item.hsTariffNumber
        self.originCountry = item.originCountry
    }
}
