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
                case .success(let data):
                    print("Step 1.1 - SearchResults: Success!")
                    self.upsertSearchResults(siteID: siteID, readOnlySearchResults: data, onCompletion: {
                        print("Step 1.2 - Upsert SearchResults to Storage: Success!")
                    })
                    //self.mapSearchResultsToCustomerObject(for: siteID, with: data, onCompletion: { _ in })
                    onCompletion(.success(()))
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
                case .failure(let error):
                    onCompletion(.failure(error))
                case .success(let customer):
                    onCompletion(.success(customer))
                }
            }
        }

    /// Maps SearchResult (/analytics/customer endpoint) to customer (/wp/v3/customer endpoint) objects
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
                    print("Step 2 - Map SearchResults to Customer: Success!")
                case .failure(_):
                    break
                }
                self.upsertCustomers(readOnlyCustomers: temp_customersHolder, onCompletion: {
                    print("Step 3 - Upsert Customer to Storage: Success!")
                })
            }
        }
    }

    func upsertSearchResults(siteID: Int64, readOnlySearchResults: [Networking.WCAnalyticsCustomer], onCompletion: @escaping () -> Void) {
        // Logic for inserting or updating in Storage will go here.
        for eachCustomer in readOnlySearchResults {
            print("Upserting SearchResults: \(eachCustomer.userID) in Storage. Name: \(eachCustomer.name ?? "Name not found")")
        }
        onCompletion()
        self.mapSearchResultsToCustomerObject(for: siteID, with: readOnlySearchResults, onCompletion: { _ in })
    }

    func upsertCustomers(readOnlyCustomers: [Networking.Customer], onCompletion: @escaping () -> Void) {
        // Logic for inserting or updating in Storage will go here.
        for eachCustomer in readOnlyCustomers {
            print("Upserting customer ID: \(eachCustomer.customerID) in Storage. Name: \(eachCustomer.firstName ?? "Name not found")")
        }
        onCompletion()
        print("Step 4 - Process completed")
    }
}
