import Foundation
import Networking
import Storage

public final class CustomerStore: Store {

    private let customerRemote: CustomerRemote
    private let searchRemote: WCAnalyticsCustomerRemote
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

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
    /// Returns [Customer] upon success, or an Error.
    /// Search results are persisted in local storage.
    ///
    /// - Parameters:
    ///   - siteID: The site for which the array of Customers should be fetched.
    ///   - keyword: Keyword that we pass to the `?query={keyword}` endpoint to perform the search
    ///   - onCompletion: Invoked when the operation finishes.
    ///
    func searchCustomers(
        for siteID: Int64,
        keyword: String,
        onCompletion: @escaping (Result<[Customer], Error>) -> Void) {
            searchRemote.searchCustomers(for: siteID, name: keyword) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let customers):
                    self.mapSearchResultsToCustomerObjects(for: siteID, with: keyword, with: customers, onCompletion: onCompletion)
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
    ///   - onCompletion: Invoked when the operation finishes. Will upsert the Customer to Storage, or return an Error.
    ///
    func retrieveCustomer(
        for siteID: Int64,
        with customerID: Int64,
        onCompletion: @escaping (Result<Customer, Error>) -> Void) {
            customerRemote.retrieveCustomer(for: siteID, with: customerID) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let customer):
                    self.upsertCustomer(siteID: siteID, readOnlyCustomer: customer, in: self.sharedDerivedStorage, onCompletion: {
                        onCompletion(.success(customer))
                    })
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
        }

    /// Maps CustomerSearchResult to Customer objects
    ///
    /// - Parameters:
    ///   - siteID: The site for which customers should be fetched.
    ///   - keyword: The keyword used for the Customer search query.
    ///   - searchResults: A WCAnalyticsCustomer collection that represents the matches we've got from the API based in our keyword search.
    ///   - onCompletion: Invoked when the operation finishes. Will map the result to a `[Customer]` entity.
    ///
    private func mapSearchResultsToCustomerObjects(for siteID: Int64,
                                                   with keyword: String,
                                          with searchResults: [WCAnalyticsCustomer],
                                                  onCompletion: @escaping (Result<[Customer], Error>) -> Void) {
        var customers = [Customer]()
        let group = DispatchGroup()
        for result in searchResults {
            // At the moment, we're not searching through non-registered customers
            // As we only search by customer ID, calls to /wc/v3/customers/0 will always fail
            // https://github.com/woocommerce/woocommerce-ios/issues/7741
            if result.userID == 0 {
                continue
            }
            group.enter()
            self.retrieveCustomer(for: siteID, with: result.userID, onCompletion: { result in
                if let customer = try? result.get() {
                    customers.append(customer)
                }
                group.leave()
            })
        }

        group.notify(queue: .main) {
            self.upsertSearchCustomerResult(
                siteID: siteID,
                keyword: keyword,
                readOnlyCustomers: customers,
                onCompletion: {
                    onCompletion(.success(customers))
                }
            )
        }
    }
}

// MARK: Storage operations
private extension CustomerStore {
    /// Inserts or updates CustomerSearchResults in Storage
    ///
    private func upsertSearchCustomerResult(siteID: Int64,
                                            keyword: String,
                                            readOnlyCustomers: [Networking.Customer],
                                            onCompletion: @escaping () -> Void) {
        sharedDerivedStorage.perform { [weak self] in
            guard let self = self else { return }
            let storedSearchResult = self.sharedDerivedStorage.loadCustomerSearchResult(siteID: siteID, keyword: keyword) ??
            self.sharedDerivedStorage.insertNewObject(ofType: Storage.CustomerSearchResult.self)

            storedSearchResult.siteID = siteID
            storedSearchResult.keyword = keyword

            for result in readOnlyCustomers {
                if let storedCustomer = self.sharedDerivedStorage.loadCustomer(siteID: siteID, customerID: result.customerID) {
                    storedSearchResult.addToCustomers(storedCustomer)
                }
            }
        }
        storageManager.saveDerivedType(derivedStorage: self.sharedDerivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Inserts or updates Customer entities into Storage
    ///
    private func upsertCustomer(siteID: Int64, readOnlyCustomer: Networking.Customer, in storage: StorageType, onCompletion: @escaping () -> Void) {

        storage.perform {
            let storageCustomer: Storage.Customer = {
                // If the specific customerID for that siteID already exists, return it
                // If doesn't, insert a new one in Storage
                if let storedCustomer = storage.loadCustomer(siteID: siteID, customerID: readOnlyCustomer.customerID) {
                    return storedCustomer
                } else {
                    return storage.insertNewObject(ofType: Storage.Customer.self)
                }
            }()
            storageCustomer.update(with: readOnlyCustomer)
        }

        storageManager.saveDerivedType(derivedStorage: storage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}
