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

    @Published private(set) var totalValue: Decimal = 0

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

    var isValidWeight: Bool {
        return Self.isWeightValid(weightPerUnit)
    }

    @Published var requiredInformationIsEntered: Bool = false

    private var cancellables = Set<AnyCancellable>()

    /// WOOMOB-891
    /// Shipments with a EU destination address must contain HS tariff number
    ///
    /// Introduced to enforce tariff validation
    /// if `true` then `hsTariffNumber` must be valid for `requiredInformationIsEntered` to be `true`
    @Published private(set) var isHSTariffNumberRequired: Bool = false

    init(itemName: String,
         itemProductID: Int64,
         itemQuantity: Decimal,
         itemValue: Double,
         itemWeight: Double,
         currencySymbol: String,
         originCountryCode: AnyPublisher<String?, Never>? = nil,
         isHSTariffNumberRequired: AnyPublisher<Bool, Never>? = nil,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.title = itemName
        self.description = itemName
        self.itemProductID = itemProductID
        self.itemQuantity = itemQuantity
        self.valuePerUnit = String(itemValue)

        /// Skip zero weight
        if Self.isWeightNonZero(itemWeight) {
            self.weightPerUnit = String(itemWeight)
        }

        self.currencySymbol = currencySymbol
        self.storageManager = storageManager

        originCountryCode?
            .assign(to: &$originCountryCode)

        isHSTariffNumberRequired?
            .assign(to: &$isHSTariffNumberRequired)

        fetchCountries()

        combineToPreselectCountry()
        combineRequiredInformationIsEntered()
        combineTotalItemValue()
    }
}

private extension WooShippingCustomsItemViewModel {
    func combineToPreselectCountry() {
        $originCountryCode
            .compactMap { $0 }
            .first(where: { !$0.isEmpty }) /// Make sure to only handle the initial value
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
        Publishers.CombineLatest4(
            $description,
            $valuePerUnit,
            $weightPerUnit,
            $selectedCountry
        )
        .combineLatest($hsTariffNumber, $isHSTariffNumberRequired)
        .sink { [weak self] result in
            guard let self else { return }

            let ((description, valuePerUnit, weightPerUnit, selectedCountry), hsTariffNumber, isHSTariffNumberRequired) = result

            let hsTariffNumberRequirementMet = (hsTariffNumber.isEmpty && !isHSTariffNumberRequired) || (isValidTariffNumber && hsTariffNumber.isNotEmpty)

            requiredInformationIsEntered = description.isNotEmpty &&
            valuePerUnit.isNotEmpty &&
            Self.isWeightValid(weightPerUnit) &&
            selectedCountry != nil &&
            hsTariffNumberRequirementMet
        }
        .store(in: &cancellables)
    }

    func combineTotalItemValue() {
        $valuePerUnit.map { [weak self] valuePerUnit in
            guard
                let self,
                currencySymbol == "$",
                let valuePerUnitDecimal = Decimal(string: valuePerUnit)
            else {
                return 0
            }

            return valuePerUnitDecimal * itemQuantity
        }
        .assign(to: &$totalValue)
    }

    /// Specifically introduced to check for a `0` value
    static func isWeightValid(_ weightString: String) -> Bool {
        return isWeightNonZero(Double(weightString) ?? 0)
    }

    static func isWeightNonZero(_ weightValue: Double) -> Bool {
        return weightValue > 0
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
