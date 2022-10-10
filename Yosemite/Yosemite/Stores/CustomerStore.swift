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

    /// Attempts to search Customers that match the given keyword, for a specific siteID.
    /// Returns Void upon success, or an Error.
    /// Search results are persisted in the local storage
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
            searchRemote.searchCustomers(for: siteID, name: keyword) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let customers):
                    print("1 - SearchCustomer: Search for keyword: \(keyword)")
                    self.upsertSearchCustomerResults(siteID: siteID, readOnlySearchResults: customers) {
                        // We'll be saving the search results to Core Data. Not implemented yet.
                        print("3 - SearchCustomer: Upsert SearchCustomer done")
                    }
                    Task {
                        try await self.mapSearchResultsToCustomerObjects(for: siteID, with: customers)
                    }
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
        }

    /// Attempts to retrieve a single Customer from a site, returning the Customer object upon success, or an Error.
    /// The fetched Customer is persisted to the local storage.
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
            customerRemote.retrieveCustomer(for: siteID, with: customerID) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let customer):
                    self.upsertCustomer(siteID: siteID, readOnlyCustomer: customer) {
                        print("6 - Customer: Upsert Customer done")
                        onCompletion(.success(customer))
                    }
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
        }

    /// Helper that acts as intermediate step between our mapping CustomerSearchResults to Customer Objects,
    /// we can use async await and map these concurrently
    private func retrieveCustomerTaskAsyncHelper(for siteID: Int64, with customerID: Int64) async throws -> Result<Customer, Error> {
        try await withCheckedThrowingContinuation { continuation in
            retrieveCustomer(for: siteID, with: customerID) { customer in
                continuation.resume(returning: customer)
                print("X - Customer: Async retrieve customer \(customerID)")
            }
        }
    }

    /// Maps CustomerSearchResult to Customer objects
    ///
    /// - Parameters:
    ///   - siteID: The site for which customers should be fetched.
    ///   - searchResults: A WCAnalyticsCustomer collection that represents the matches we've got from the API based in our keyword search
    ///   - onCompletion: Invoked when the operation finishes, returns a Customer object, which we'll be upserting into Core Data, or an Error.
    ///
    private func mapSearchResultsToCustomerObjects(for siteID: Int64,
                                                  with searchResults: [WCAnalyticsCustomer]) async throws {
        for result in searchResults {
            // TODO: TaskGroup
            print("4 - Mapping: SearchResult to Customer \(result.userID)")
            let _ = try await retrieveCustomerTaskAsyncHelper(for: siteID, with: result.userID)
            self.upsertSearchCustomerResults(siteID: siteID, readOnlySearchResults: searchResults, onCompletion: {})
        }
    }

    /// Inserts or updates CustomerSearchResults in Storage
    ///
    private func upsertSearchCustomerResults(siteID: Int64, readOnlySearchResults: [Networking.WCAnalyticsCustomer], onCompletion: @escaping () -> Void) {

        for searchResult in readOnlySearchResults {
            // Logic for inserting or updating in Storage will go here.
            print("2 - SearchCustomer: Saving SearchCustomerResults for UserID: \(searchResult.userID). Name: \(searchResult.name ?? "Not found")")
        }
        onCompletion()
    }

    /// Inserts or updates Customers in Storage
    ///
    private func upsertCustomer(siteID: Int64, readOnlyCustomer: Networking.Customer, onCompletion: @escaping () -> Void) {
            // Logic for inserting or updating in Storage will go here.
            print("5 - Customer: Saving Customer for UserID: \(readOnlyCustomer.customerID). Name: \(readOnlyCustomer.firstName ?? "Not found")")
        onCompletion()
    }
}
