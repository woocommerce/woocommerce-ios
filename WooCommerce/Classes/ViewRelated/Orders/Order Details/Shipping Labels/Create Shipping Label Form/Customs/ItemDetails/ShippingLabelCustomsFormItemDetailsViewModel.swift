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

    /// Whether all fields are validated.
    ///
    @Published private(set) var validItem: Bool = false

    /// The validated tariff number to be observed by `ShippingLabelCustomsFormInputViewModel`
    /// to calculate total value for each tariff number.
    ///
    @Published private(set) var validatedHSTariffNumber: String?

    /// The validated total value of the item. This will be observed by
    /// `ShippingLabelCustomsFormInputViewModel` to calculate total value of each tariff number.
    ///
    @Published private(set) var validatedTotalValue: Decimal?

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
        self.value = NumberFormatter.localizedString(from: NSNumber(value: item.value)) ?? String(item.value)
        self.weight = NumberFormatter.localizedString(from: NSNumber(value: item.weight)) ?? String(item.weight)
        self.hsTariffNumber = item.hsTariffNumber
        self.allCountries = countries
        self.currency = currency
        self.weightUnit = weightUnit ?? ""
        self.originCountry = countries.first(where: { $0.code == item.originCountry }) ?? Country(code: "", name: "", states: [])

        configureValidatedTotalValue()
        configureValidatedHSTariffNumber()
        configureValidationCheck()
    }
}

// MARK: - Validation
//
extension ShippingLabelCustomsFormItemDetailsViewModel {
    var hasValidDescription: Bool {
        validateDescription(description)
    }

    var validatedValue: Double? {
        getValidatedValue(from: value)
    }

    var validatedWeight: Double? {
        getValidatedWeight(from: weight)
    }

    var hasValidOriginCountry: Bool {
        validateCountry(originCountry)
    }

    var hasValidHSTariffNumber: Bool {
        getValidateHSTariffNumber(hsTariffNumber) != nil
    }
}

// MARK: - Helper methods
//
private extension ShippingLabelCustomsFormItemDetailsViewModel {
    func validateDescription(_ description: String) -> Bool {
        description.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
    }

    func getValidatedValue(from value: String) -> Double? {
        guard let numericValue = NumberFormatter.double(from: value), numericValue > 0 else {
            return nil
        }
        return numericValue
    }

    func getValidatedWeight(from weight: String) -> Double? {
        guard let numericWeight = NumberFormatter.double(from: weight), numericWeight > 0 else {
            return nil
        }
        return numericWeight
    }

    func validateCountry(_ originCountry: Country) -> Bool {
        originCountry.code.isNotEmpty
    }

    func getValidateHSTariffNumber(_ hsTariffNumber: String) -> String? {
        if hsTariffNumber.isNotEmpty,
           (hsTariffNumber.count != Constants.hsTariffNumberCharacterLimit ||
                hsTariffNumber.filter({ "0"..."9" ~= $0 }).count != 6) {
            return nil
        }
        return hsTariffNumber
    }

    /// Observe changes in all fields to check if everything is validated.
    ///
    func configureValidationCheck() {
        let groupOne = $description.combineLatest($value, $weight)
        let groupTwo = $hsTariffNumber.combineLatest($originCountry)
        groupOne.combineLatest(groupTwo)
            .map { [weak self] groupOne, groupTwo -> Bool in
                guard let self = self else {
                    return false
                }
                let (description, value, weight) = groupOne
                let (hsTariffNumber, originCountry) = groupTwo
                return self.validateDescription(description) &&
                    self.validateCountry(originCountry) &&
                    self.getValidateHSTariffNumber(hsTariffNumber) != nil &&
                    self.getValidatedValue(from: value) != nil &&
                    self.getValidatedWeight(from: weight) != nil
            }
            .removeDuplicates()
            .assign(to: &$validItem)
    }

    /// Update validated total value on change of total value.
    ///
    func configureValidatedTotalValue() {
        $value
            .map { [weak self] value -> Decimal? in
                guard let self = self,
                      let validatedValue = self.getValidatedValue(from: value) else {
                    return nil
                }
                return Decimal(validatedValue) * self.quantity
            }
            .assign(to: &$validatedTotalValue)
    }

    /// Update validated tariff number on change of tariff number.
    ///
    func configureValidatedHSTariffNumber() {
        $hsTariffNumber
            .map { [weak self] number -> String? in
                self?.getValidateHSTariffNumber(number)
            }
            .assign(to: &$validatedHSTariffNumber)
    }

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
