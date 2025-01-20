import Yosemite
import SwiftUI
import Combine
import protocol Storage.StorageManagerType

struct WooShippingCustomsCountry: Hashable {
    let code: String
    let name: String
}

final class WooShippingCustomsItemViewModel: ObservableObject {
    @Published var title: String
    @Published var description: String = ""
    @Published var hsTariffNumber: String = ""
    @Published var valuePerUnit: String = ""
    @Published var weightPerUnit: String = ""
    @Published var originCountry: WooShippingCustomsCountry

    private let storageManager: StorageManagerType
    private let stores: StoresManager
    private let siteID: Int64
    let currencySymbol: String
    let orderItem: OrderItem

    let hsTariffURL = WooConstants.URLs.hsTariffURL.asURL()

    private lazy var resultsController: ResultsController<StorageCountry> = {
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController(storageManager: storageManager, matching: nil, sortedBy: [descriptor])
    }()

    var countries: [WooShippingCustomsCountry] {
        let countries = resultsController.fetchedObjects

        // This removes the states property because:
        // - It's not necessary to display the list
        // - As we retrieve a different order on the states array property from the ResultsController, it might mess the Equality comparison
        return countries.map { WooShippingCustomsCountry(code: $0.code, name: $0.name) }
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
    @Published var internationalTransactionNumberIsRequired: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init(originCountry: WooShippingCustomsCountry,
         orderItem: OrderItem,
         currencySymbol: String,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores) {
        self.title = orderItem.name
        self.originCountry = originCountry
        self.orderItem = orderItem
        self.currencySymbol = currencySymbol
        self.storageManager = storageManager
        self.stores = stores
        self.siteID = stores.sessionManager.defaultStoreID ?? Int64.min

        fetchCountries()
        combineRequiredInformationIsEntered()
        combineInternationalTransactionNumberIsRequired()
    }
}

extension WooShippingCustomsItemViewModel {
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
        Publishers.CombineLatest3($description, $valuePerUnit, $weightPerUnit)
            .sink { [weak self] description, valuePerUnit, weightPerUnit in
                self?.requiredInformationIsEntered = description.isNotEmpty && valuePerUnit.isNotEmpty && weightPerUnit.isNotEmpty
            }
            .store(in: &cancellables)
    }

    func combineInternationalTransactionNumberIsRequired() {
        Publishers.CombineLatest($valuePerUnit, $hsTariffNumber)
            .sink { [weak self] valuePerUnit, hsTariffNumber in
                guard let self = self else { return }

                // Items valued more than $2500 with a valid HSTariff Number require an International Transaction Number
                self.internationalTransactionNumberIsRequired = self.currencySymbol == "$" &&
                (Double(valuePerUnit) ?? 0) > 2500 &&
                hsTariffNumber.isNotEmpty &&
                isValidTariffNumber
            }
            .store(in: &cancellables)
    }
}
