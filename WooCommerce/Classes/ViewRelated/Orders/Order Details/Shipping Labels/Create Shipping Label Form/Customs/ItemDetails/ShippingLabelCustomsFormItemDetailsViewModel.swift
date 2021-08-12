import Foundation
import Yosemite

final class ShippingLabelCustomsFormItemDetailsViewModel: ObservableObject {
    /// Product ID of the item.
    ///
    let productID: Int64

    /// Description for the item.
    ///
    @Published var description: String

    /// Price of item per unit.
    ///
    @Published var value: String

    /// Weight of item per unit.
    ///
    @Published var weight: String

    /// HS tariff number, empty if N/A.
    ///
    @Published var hsTariffNumber: String

    /// Origin country code of item.
    ///
    @Published var originCountry: Country

    /// Persisted countries to select from.
    ///
    let allCountries: [Country]

    /// Validated item if all fields are valid.
    ///
    private(set) var validatedItem: ShippingLabelCustomsForm.Item?

    init(item: ShippingLabelCustomsForm.Item, countries: [Country]) {
        self.productID = item.productID
        self.description = item.description
        self.value = String(item.value)
        self.weight = String(item.weight)
        self.hsTariffNumber = item.hsTariffNumber
        self.allCountries = countries
        self.originCountry = countries.first(where: { $0.code == item.originCountry }) ?? Country(code: "", name: "", states: [])
    }
}
