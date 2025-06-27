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

    private let storageManager: StorageManagerType
    private let stores: StoresManager
    private let siteID: Int64
    let currencySymbol: String

    let itemProductID: Int64
    let itemQuantity: Decimal

    let hsTariffURL = WooConstants.URLs.hsTariffURL.asURL()

    private lazy var resultsController: ResultsController<StorageCountry> = {
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController(storageManager: storageManager, matching: nil, sortedBy: [descriptor])
    }()

    @Published private(set) var selectedCountry: Country?

    var countries: [Country] {
        resultsController.fetchedObjects
    }

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

    @Published var requiredInformationIsEntered: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init(itemName: String,
         itemProductID: Int64,
         itemQuantity: Decimal,
         itemValue: Double,
         itemWeight: Double,
         currencySymbol: String,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores) {
        self.title = itemName
        self.description = itemName
        self.itemProductID = itemProductID
        self.itemQuantity = itemQuantity
        self.valuePerUnit = String(itemValue)
        self.weightPerUnit = String(itemWeight)
        self.currencySymbol = currencySymbol
        self.storageManager = storageManager
        self.stores = stores
        self.siteID = stores.sessionManager.defaultStoreID ?? Int64.min

        fetchCountries()
        combineRequiredInformationIsEntered()
        combineHSTariffNumberTotalValue()
    }
}

private extension WooShippingCustomsItemViewModel {
    func fetchCountries() {
        try? resultsController.performFetch()
        let action = DataAction.synchronizeCountries(siteID: siteID) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success:
                try? self.resultsController.performFetch()
            case .failure:
                break
            }
        }

        stores.dispatch(action)
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
