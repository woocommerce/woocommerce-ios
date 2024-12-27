import Yosemite
import SwiftUI
import protocol Storage.StorageManagerType

final class WooShippingCustomsItemViewModel: ObservableObject {
    @Published var title: String
    @Published var description: String
    @Published var hsTariffNumber: String
    @Published var valuePerUnit: String
    @Published var weightPerUnit: String
    @Published var originCountry: Country

    var informationIsMissing: Bool = true

    private let storageManager: StorageManagerType
    private let stores: StoresManager
    private let siteID: Int64

    private lazy var resultsController: ResultsController<StorageCountry> = {
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController(storageManager: storageManager, matching: nil, sortedBy: [descriptor])
    }()

    var countries: [Country] {
        resultsController.fetchedObjects
    }

    let hsTariffURL: URL? = .init(string: "https://woocommerce.com/document/woocommerce-shipping-and-tax/woocommerce-shipping/#section-29")

    init(title: String,
         description: String,
         hsTariffNumber: String,
         valuePerUnit: String,
         weightPerUnit: String,
         originCountry: Country,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores) {
        self.title = title
        self.description = description
        self.hsTariffNumber = hsTariffNumber
        self.valuePerUnit = valuePerUnit
        self.weightPerUnit = weightPerUnit
        self.originCountry = originCountry
        self.storageManager = storageManager
        self.stores = stores
        self.siteID = stores.sessionManager.defaultStoreID ?? Int64.min

        fetchCountries()
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
}
