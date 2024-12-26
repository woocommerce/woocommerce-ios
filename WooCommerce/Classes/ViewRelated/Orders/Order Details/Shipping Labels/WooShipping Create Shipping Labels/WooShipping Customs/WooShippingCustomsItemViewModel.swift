import Yosemite
import SwiftUI

final class WooShippingCustomsItemViewModel: ObservableObject {
    @Published var title: String
    @Published var description: String
    @Published var hsTariffNumber: String
    @Published var valuePerUnit: String
    @Published var weightPerUnit: String
    @Published var originCountry: Country

    var informationIsMissing: Bool = true

    let allCountries: [Country]

    let hsTariffURL: URL? = .init(string: "https://woocommerce.com/document/woocommerce-shipping-and-tax/woocommerce-shipping/#section-29")

    init(title: String, description: String, hsTariffNumber: String, valuePerUnit: String, weightPerUnit: String, originCountry: Country, allCountries: [Country]) {
        self.title = title
        self.description = description
        self.hsTariffNumber = hsTariffNumber
        self.valuePerUnit = valuePerUnit
        self.weightPerUnit = weightPerUnit
        self.originCountry = originCountry
        self.allCountries = allCountries
    }
}
