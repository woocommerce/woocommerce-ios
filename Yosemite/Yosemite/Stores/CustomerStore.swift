import Foundation
import Networking
import Storage

public final class CustomerStore: Store {

    private let customerRemote: CustomerRemote
    private let searchRemote: WCAnalyticsCustomerRemote

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         customerRemote: CustomerRemote,
         searchRemote: WCAnalyticsCustomerRemote) {
        self.customerRemote = customerRemote
        self.searchRemote = searchRemote

        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public override convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  customerRemote: CustomerRemote(network: network),
                  searchRemote: WCAnalyticsCustomerRemote(network: network))
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: CustomerAction.self)
    }

    /// Receives and executes Actions.
    ///
    /// - Parameters:
    ///   - action: An action to handle. Must be a `CustomerAction`
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? CustomerAction else {
            assertionFailure("CustomerStore received an unsupported action")
            return
        }
        switch action {
        case .searchCustomers(siteID: let siteID, keyword: let keyword, onCompletion: let onCompletion):
            searchCustomers(for: siteID, keyword: keyword, onCompletion: onCompletion)
        case .retrieveCustomer(siteID: let siteID, customerID: let customerID, onCompletion: let onCompletion):
            retrieveCustomer(for: siteID, with: customerID, onCompletion: onCompletion)
        case .upsertSearchResults(siteID: let siteID, readOnlySearchResults: let readOnlySearchResults, onCompletion: let onCompletion):
            upsertSearchResults(siteID: siteID, readOnlySearchResults: readOnlySearchResults, onCompletion: onCompletion)
        case .upsertCustomers(readOnlyCustomers: let readOnlyCustomers, onCompletion: let onCompletion):
            upsertCustomers(readOnlyCustomers: readOnlyCustomers, onCompletion: onCompletion)
        }
    }

    /// Attempts to search Customers that match the given keyword, for a specific siteID
    /// Returns Void upon success, or an Error
    ///
    /// - Parameters:
    ///   - siteID: The site for which customers should be fetched.
    ///   - keyword: Keyword to perform the search for WCAnalyticsCustomer to be fetched.
    ///   - onCompletion: Invoked when the operation finishes.
    ///
    func searchCustomers(
        for siteID: Int64,
        keyword: String,
        onCompletion: @escaping (Result<Void, Error>) -> Void) {
            searchRemote.searchCustomers(for: siteID, name: keyword) { result in
                switch result {
                case .success(let customers):
                    self.upsertSearchResults(siteID: siteID, readOnlySearchResults: customers) {
                        onCompletion(.success(()))
                    }
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
        }

    /// Attempts to retrieve a single Customer from a site, returning the Customer object upon success, or an Error.
    ///
    /// - Parameters:
    ///   - siteID: The site for which customers should be fetched.
    ///   - customerID: ID of the Customer to be fetched.
    ///   - onCompletion: Invoked when the operation finishes.
    ///
    func retrieveCustomer(
        for siteID: Int64,
        with customerID: Int64,
        onCompletion: @escaping (Result<Customer, Error>) -> Void) {
            customerRemote.retrieveCustomer(for: siteID, with: customerID) { result in
                switch result {
                case .success(let customer):
                    onCompletion(.success(customer))
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
        }

    /// Maps CustomerSearchResult to Customer objects
    ///
    /// - Parameters:
    ///   - siteID: The site for which customers should be fetched.
    ///   - data: A WCAnalyticsCustomer collection that represents the matches we've got from the API based in our keyword search
    ///   - onCompletion: Invoked when the operation finishes, returns an array of Customer objects, which we'll be upserting into Core Data, or an Error.
    ///
    func mapSearchResultsToCustomerObject(for siteID: Int64, with data: [WCAnalyticsCustomer], onCompletion: @escaping (Result<[Customer], Error>) -> Void) {
        var temp_customersHolder = [Customer]()

        for each in data {
            retrieveCustomer(for: siteID, with: each.userID) { customer in
                switch customer {
                case .success(let customer):
                    temp_customersHolder.append(customer)
                case .failure(_):
                    break
                }
            }
        }
    }

    /// Inserts or updates CustomerSearchResults in Storage
    ///
    func upsertSearchResults(siteID: Int64, readOnlySearchResults: [Networking.WCAnalyticsCustomer], onCompletion: @escaping () -> Void) {

        for searchResult in readOnlySearchResults {
            // Logic for inserting or updating in Storage will go here.
            print("Upserting SearchResults: \(searchResult.userID) in Storage. Name: \(searchResult.name ?? "Name not found")")
        }
    }

    /// Inserts or updates Customers in Storage
    ///
    func upsertCustomers(readOnlyCustomers: [Networking.Customer], onCompletion: @escaping () -> Void) {

        for customer in readOnlyCustomers {
            // Logic for inserting or updating in Storage will go here.
            print("Upserting customer ID: \(customer.customerID) in Storage. Name: \(customer.firstName ?? "Name not found")")
        }
    }
}
