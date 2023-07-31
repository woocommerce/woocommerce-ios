import Foundation
import Yosemite

final class CustomerSelectorViewModel {
    private let stores: StoresManager
    private let siteID: Int64

    private let onCustomerSelected: (Customer) -> Void

    init(siteID: Int64,
         onCustomerSelected: @escaping (Customer) -> Void,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
        self.onCustomerSelected = onCustomerSelected
    }

    func onCustomerSelected(_ customer: Customer, onCompletion: @escaping () -> Void) {
        stores.dispatch(CustomerAction.retrieveCustomer(siteID: siteID, customerID: customer.customerID, onCompletion: { [weak self] result in
            switch result {
            case .success(let customer):
                self?.onCustomerSelected(customer)
                onCompletion()
            case .failure(_):
                break
            }
        }))
    }
}
