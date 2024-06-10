import Foundation
import Yosemite

final class CustomerSelectorViewModel {
    private let stores: StoresManager
    private let siteID: Int64

    private let onCustomerSelected: (Customer) -> Void

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         onCustomerSelected: @escaping (Customer) -> Void) {
        self.siteID = siteID
        self.stores = stores
        self.onCustomerSelected = onCustomerSelected
    }

    func isEligibleForAdvancedSearch(completion: @escaping (Bool) -> Void) {
        // Fetches WC plugin.
        let action = SystemStatusAction.fetchSystemPlugin(siteID: siteID, systemPluginName: Constants.wcPluginName) { wcPlugin in
            guard let wcPlugin = wcPlugin, wcPlugin.active else {
                return completion(false)
            }

            let isCustomerAdvanceSearchSupportedByWCPlugin = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                               minimumRequired: Constants.wcPluginMinimumVersion)
            completion(isCustomerAdvanceSearchSupportedByWCPlugin)
        }
        stores.dispatch(action)
    }

    /// Loads the customer list data, a lighter version of the model without all the information
    ///
    func loadCustomersListData(onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        stores.dispatch(CustomerAction.synchronizeLightCustomersData(siteID: siteID,
                                                                     pageNumber: Constants.firstPageNumber,
                                                                     pageSize: Constants.pageSize,
                                                                     orderby: .name,
                                                                     order: .asc,
                                                                     filterEmpty: .email,
                                                                     onCompletion: onCompletion))
    }

    /// Loads the whole customer information and calls the completion closures
    ///
    func onCustomerSelected(_ customer: Customer, onCompletion: @escaping (Result<(), Error>) -> Void) {
        guard customer.customerID != 0 else {
            // The customer is not registered, we won't get any further information. Dismiss and return data
            onCustomerSelected(customer)
            onCompletion(.success(()))

            return
        }
        // Get the full data about that customer
        stores.dispatch(CustomerAction.retrieveCustomer(siteID: siteID, customerID: customer.customerID, onCompletion: { [weak self] result in
            switch result {
            case .success(let customer):
                self?.onCustomerSelected(customer)
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(error))
                break
            }
        }))
    }
}

private extension CustomerSelectorViewModel {
    enum Constants {
        static let pageSize = 25
        static let firstPageNumber = 1
        static let wcPluginName = "WooCommerce"
        static let wcPluginMinimumVersion = "8.0.0-beta.1"
    }
}
