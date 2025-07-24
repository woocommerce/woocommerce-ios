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
        guard hsTariffNumber.isNotEmpty else {
            return true
        }

        // Check if the string contains only digits
        let digitsOnly = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: hsTariffNumber))
        guard digitsOnly else { return false }

        // Check the length of the string
        let length = hsTariffNumber.count
        return length >= 6 && length <= 12
    }

    var isValidWeight: Bool {
        return Self.isWeightValid(weightPerUnit)
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

        /// Skip zero weight
        if Self.isWeightNonZero(itemWeight) {
            self.weightPerUnit = String(itemWeight)
        }

        self.currencySymbol = currencySymbol
        self.storageManager = storageManager

        originCountryCode?
            .assign(to: &$originCountryCode)

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
                guard let self else { return }
                requiredInformationIsEntered = description.isNotEmpty &&
                valuePerUnit.isNotEmpty &&
                Self.isWeightValid(weightPerUnit) &&
                selectedCountry != nil
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
