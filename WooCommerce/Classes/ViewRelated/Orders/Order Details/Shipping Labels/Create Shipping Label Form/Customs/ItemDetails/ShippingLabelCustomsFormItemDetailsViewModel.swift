import Foundation
import Yosemite

final class ShippingLabelCustomsFormItemDetailsViewModel: ObservableObject {
    /// Product ID of the item.
    ///
    let productID: Int64

    /// Currency used in store.
    ///
    let currency: String

    /// Weight unit used in store.
    ///
    let weightUnit: String

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
    @Published var hsTariffNumber: String {
        didSet {
            limitHSTariffNumberLength()
        }
    }

    /// Origin country code of item.
    ///
    @Published var originCountry: Country

    /// Persisted countries to select from.
    ///
    let allCountries: [Country]

    /// Validated item if all fields are valid.
    ///
    var validatedItem: ShippingLabelCustomsForm.Item? {
        guard let value = validatedValue,
              let weight = validatedWeight,
              hasValidDescription,
              hasValidHSTariffNumber,
              hasValidOriginCountry else {
            return nil
        }
        return ShippingLabelCustomsForm.Item(description: description,
                                             quantity: quantity,
                                             value: value,
                                             weight: weight,
                                             hsTariffNumber: hsTariffNumber,
                                             originCountry: originCountry.code,
                                             productID: productID)
    }

    /// Quantity of items to be declared.
    ///
    private let quantity: Decimal

    init(item: ShippingLabelCustomsForm.Item, countries: [Country], currency: String, weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit) {
        self.quantity = item.quantity
        self.productID = item.productID
        self.description = item.description
        self.value = String(item.value)
        self.weight = String(item.weight)
        self.hsTariffNumber = item.hsTariffNumber
        self.allCountries = countries
        self.currency = currency
        self.weightUnit = weightUnit ?? ""
        self.originCountry = countries.first(where: { $0.code == item.originCountry }) ?? Country(code: "", name: "", states: [])
    }
}

// MARK: - Validation
//
extension ShippingLabelCustomsFormItemDetailsViewModel {
    var hasValidDescription: Bool {
        description.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
    }

    var validatedValue: Double? {
        guard let numericValue = Double(value), numericValue > 0 else {
            return nil
        }
        return numericValue
    }

    var validatedWeight: Double? {
        guard let numericWeight = Double(weight), numericWeight > 0 else {
            return nil
        }
        return numericWeight
    }

    var hasValidOriginCountry: Bool {
        originCountry.code.isNotEmpty
    }

    var hasValidHSTariffNumber: Bool {
        if hsTariffNumber.isNotEmpty,
           (hsTariffNumber.count != Constants.hsTariffNumberCharacterLimit ||
                hsTariffNumber.filter({ "0"..."9" ~= $0 }).count != 6) {
            return false
        }
        return true
    }
}

// MARK: - Helpers
//
private extension ShippingLabelCustomsFormItemDetailsViewModel {
    /// Limit length HS Tariff Number to only 6 characters max.
    ///
    func limitHSTariffNumberLength() {
        if hsTariffNumber.count > Constants.hsTariffNumberCharacterLimit {
            hsTariffNumber = String(hsTariffNumber.prefix(Constants.hsTariffNumberCharacterLimit))
        }
    }
}

// MARK: - Subtypes
//
private extension ShippingLabelCustomsFormItemDetailsViewModel {
    enum Constants {
        static let hsTariffNumberCharacterLimit = 6
    }
}
