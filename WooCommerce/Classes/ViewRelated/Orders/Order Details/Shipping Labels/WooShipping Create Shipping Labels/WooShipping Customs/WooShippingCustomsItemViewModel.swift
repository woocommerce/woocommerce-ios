import Yosemite
import SwiftUI
import Combine
import protocol Storage.StorageManagerType

final class WooShippingCustomsItemViewModel: ObservableObject {
    @Published var title: String
    @Published var description: String = ""
    @Published var hsTariffNumber: String = ""
    @Published var valuePerUnit: String = ""
    @Published var weightPerUnit: String = ""
    // Useful to determine externally if the shipping requires an ITN
    @Published var hsTariffNumberTotalValue: (String, Decimal)?

    @Published private var originCountryCode: String?

    private let storageManager: StorageManagerType
    let currencySymbol: String

    let itemProductID: Int64
    let itemQuantity: Decimal

    let hsTariffURL = WooConstants.URLs.hsTariffURL.asURL()

    private lazy var resultsController: ResultsController<StorageCountry> = {
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController(storageManager: storageManager, matching: nil, sortedBy: [descriptor])
    }()

    @Published private(set) var selectedCountry: Country?

    @Published private(set) var countries: [Country] = []

    var totalValue: Decimal {
        guard currencySymbol == "$",
              let valuePerUnitDecimal = Decimal(string: valuePerUnit) else {
            return 0
        }
        return valuePerUnitDecimal * itemQuantity
    }

    /// View model for selecting a country from a list.
    var countrySelectorVM: CountrySelectorViewModel {
        let selectedCountryBinding = Binding<AreaSelectorCommandProtocol?>(
            get: { self.selectedCountry },
            set: { self.selectedCountry = $0 as? Country }
        )
        return CountrySelectorViewModel(countries: countries, selected: selectedCountryBinding)
    }

    var isValidTariffNumber: Bool {
        return HSTariffNumberValidator.isNumberValid(hsTariffNumber)
    }

    var sanitizedHSTariffNumber: String {
        HSTariffNumberValidator.sanitize(hsTariffNumber)
    }

    @Published var requiredInformationIsEntered: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init(itemName: String,
         itemProductID: Int64,
         itemQuantity: Decimal,
         itemValue: Double,
         itemWeight: Double,
         currencySymbol: String,
         originCountryCode: AnyPublisher<String?, Never>? = nil,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.title = itemName
        self.description = itemName
        self.itemProductID = itemProductID
        self.itemQuantity = itemQuantity
        self.valuePerUnit = String(itemValue)
        self.weightPerUnit = String(itemWeight)
        self.currencySymbol = currencySymbol
        self.storageManager = storageManager

        originCountryCode?
            .assign(to: &$originCountryCode)

        fetchCountries()

        combineToPreselectCountry()
        combineRequiredInformationIsEntered()
        combineHSTariffNumberTotalValue()
    }
}

private extension WooShippingCustomsItemViewModel {
    func combineToPreselectCountry() {
        $originCountryCode
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .first() /// Make sure to only handle the initial value
            .combineLatest($countries)
            .map { code, countries in
                return countries.first(where: { $0.code == code })
            }
            .assign(to: &$selectedCountry)
    }

    func fetchCountries() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateCountries()
        }

        resultsController.onDidResetContent = { [weak self] in
            self?.updateCountries()
        }

        try? resultsController.performFetch()
        updateCountries()
    }

    func updateCountries() {
        countries = resultsController.fetchedObjects
    }

    func combineRequiredInformationIsEntered() {
        Publishers.CombineLatest4($description, $valuePerUnit, $weightPerUnit, $selectedCountry)
            .sink { [weak self] description, valuePerUnit, weightPerUnit, selectedCountry in
                self?.requiredInformationIsEntered = description.isNotEmpty && valuePerUnit.isNotEmpty && weightPerUnit.isNotEmpty && selectedCountry != nil
            }
            .store(in: &cancellables)
    }

    func combineHSTariffNumberTotalValue() {
        Publishers.CombineLatest($valuePerUnit, $hsTariffNumber)
            .sink { [weak self] valuePerUnit, hsTariffNumber in
                guard let self = self else { return }

                guard self.currencySymbol == "$",
                      let valuePerUnitDecimal = Decimal(string: valuePerUnit),
                      hsTariffNumber.isNotEmpty,
                      isValidTariffNumber else {
                    self.hsTariffNumberTotalValue = nil
                    return
                }

                self.hsTariffNumberTotalValue = (hsTariffNumber, valuePerUnitDecimal * itemQuantity)
            }
            .store(in: &cancellables)
    }
}

/// Follows validation logic from `woocommerce-shipping/client/utils/customs.ts`
enum HSTariffNumberValidator {
    static let pattern = "^(\\d{1,2}\\.?){3,6}$"

    /// Check if the HS Tariff Number is valid.
    /// It should be a string of 6 to 12 digits, with optional dots in between every 2 digits.
    /// - Parameter tariffNumber: The tariff number string.
    /// - Returns: `Bool` if tariff number valid or not.
    static func isNumberValid(_ tariffNumber: String) -> Bool {
        if tariffNumber.isEmpty {
            return true
        }

        let patternRange = tariffNumber.range(
            of: pattern,
            options: .regularExpression
        )

        if patternRange == nil {
            return false
        }

        let digitsOnly = tariffNumber.components(
            separatedBy: CharacterSet.decimalDigits.inverted
        ).joined()
        let count = digitsOnly.count
        return count >= 6 && count <= 12
    }

    /// Sanitize the HS Tariff Number
    /// Remove all non-digit characters
    /// - Parameter tariffNumber: The tariff number string.
    /// - Returns: Tariff string without non-digit characters
    static func sanitize(_ tariffNumber: String) -> String {
        return tariffNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
}
