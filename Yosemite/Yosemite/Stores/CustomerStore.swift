import Foundation
import Networking
import Storage

public final class CustomerStore: Store {
    private let customerRemote: CustomerRemote
    private let wcAnalyticsCustomerRemote: WCAnalyticsCustomerRemote
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         customerRemote: CustomerRemote,
         searchRemote: WCAnalyticsCustomerRemote) {
        self.customerRemote = customerRemote
        self.wcAnalyticsCustomerRemote = searchRemote

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
        case let .searchCustomers(siteID: siteID,
                                  pageNumber: pageNumber,
                                  pageSize: pageSize,
                                  orderby: orderby,
                                  order: order,
                                  keyword: keyword,
                                  retrieveFullCustomersData: retrieveFullCustomersData,
                                  filter: filter,
                                  filterEmpty: filterEmpty,
                                  onCompletion: onCompletion):
            searchCustomers(for: siteID,
                            pageNumber: pageNumber,
                            pageSize: pageSize,
                            orderby: orderby,
                            order: order,
                            keyword: keyword,
                            retrieveFullCustomersData: retrieveFullCustomersData,
                            filter: filter,
                            filterEmpty: filterEmpty,
                            onCompletion: onCompletion)
        case let .searchWCAnalyticsCustomers(siteID, pageNumber, pageSize, keyword, filter, onCompletion):
            searchWCAnalyticsCustomers(for: siteID, pageNumber: pageNumber, pageSize: pageSize, keyword: keyword, filter: filter, onCompletion: onCompletion)
        case .retrieveCustomer(siteID: let siteID, customerID: let customerID, onCompletion: let onCompletion):
            retrieveCustomer(for: siteID, with: customerID, onCompletion: onCompletion)
        case let .synchronizeLightCustomersData(siteID, pageNumber, pageSize, orderby, order, filterEmpty, onCompletion):
            synchronizeLightCustomersData(siteID: siteID,
                                          pageNumber: pageNumber,
                                          pageSize: pageSize,
                                          orderby: orderby,
                                          order: order,
                                          filterEmpty: filterEmpty,
                                          onCompletion: onCompletion)
        case let .synchronizeAllCustomers(siteID, pageNumber, pageSize, onCompletion):
            synchronizeAllCustomers(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .deleteAllCustomers(siteID: let siteID, onCompletion: let onCompletion):
            deleteAllCustomers(from: siteID, onCompletion: onCompletion)
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
        pageNumber: Int,
        pageSize: Int,
        orderby: WCAnalyticsCustomerRemote.OrderBy,
        order: WCAnalyticsCustomerRemote.Order,
        keyword: String,
        retrieveFullCustomersData: Bool,
        filter: CustomerSearchFilter,
        filterEmpty: WCAnalyticsCustomerRemote.FilterEmpty?,
        onCompletion: @escaping (Result<(), Error>) -> Void) {
            wcAnalyticsCustomerRemote.searchCustomers(for: siteID,
                                                      pageNumber: pageNumber,
                                                      pageSize: pageSize,
                                                      orderby: orderby,
                                                      order: order,
                                                      keyword: keyword,
                                                      filter: filter.rawValue,
                                                      filterEmpty: filterEmpty) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let customers):
                    if retrieveFullCustomersData {
                        self.mapSearchResultsToCustomerObjects(for: siteID, with: keyword, with: customers, onCompletion: onCompletion)
                    } else {
                        self.upsertCustomersAndSave(siteID: siteID,
                                             readOnlyCustomers: customers,
                                             shouldDeleteExistingCustomers: pageNumber == 1,
                                             keyword: keyword,
                                             in: self.sharedDerivedStorage,
                                             onCompletion: {
                            onCompletion(.success(()))
                        })
                    }
                case .failure(let error):
                    onCompletion(.failure(error))
                }
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
    func searchWCAnalyticsCustomers(for siteID: Int64,
                                    pageNumber: Int,
                                    pageSize: Int,
                                    keyword: String,
                                    filter: CustomerSearchFilter,
                                    onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        wcAnalyticsCustomerRemote.searchCustomers(for: siteID,
                                                  pageNumber: pageNumber,
                                                  pageSize: pageSize,
                                                  orderby: .dateLastActive,
                                                  order: .desc,
                                                  keyword: keyword,
                                                  filter: filter.rawValue) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(customers):
                self.upsertWCAnalyticsCustomersAndSave(siteID: siteID,
                                                       readOnlyCustomers: customers,
                                                       shouldDeleteExistingCustomers: filter != .all,
                                                       keyword: keyword,
                                                       in: self.sharedDerivedStorage) {
                    let hasNextPage = customers.count == pageSize
                    onCompletion(.success(hasNextPage))
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
                    self.upsertCustomersAndSave(siteID: siteID, readOnlyCustomers: [customer], in: self.sharedDerivedStorage, onCompletion: {
                        onCompletion(.success(customer))
                    })
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
    }

    func synchronizeLightCustomersData(siteID: Int64,
                                       pageNumber: Int,
                                       pageSize: Int,
                                       orderby: WCAnalyticsCustomerRemote.OrderBy,
                                       order: WCAnalyticsCustomerRemote.Order,
                                       filterEmpty: WCAnalyticsCustomerRemote.FilterEmpty?,
                                       onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        wcAnalyticsCustomerRemote.loadCustomers(for: siteID,
                                                pageNumber: pageNumber,
                                                pageSize: pageSize,
                                                orderby: orderby,
                                                order: order,
                                                filterEmpty: filterEmpty) { result in
            switch result {
            case .success(let customers):
                self.upsertCustomersAndSave(siteID: siteID,
                                     readOnlyCustomers: customers,
                                     shouldDeleteExistingCustomers: pageNumber == 1,
                                     in: self.sharedDerivedStorage,
                                     onCompletion: {
                    onCompletion(.success(!customers.isEmpty))
                })
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    func synchronizeAllCustomers(siteID: Int64,
                                 pageNumber: Int,
                                 pageSize: Int,
                                 onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        wcAnalyticsCustomerRemote.loadCustomers(for: siteID,
                                                pageNumber: pageNumber,
                                                pageSize: pageSize,
                                                orderby: .dateLastActive,
                                                order: .desc) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(customers):
                self.upsertWCAnalyticsCustomersAndSave(siteID: siteID,
                                                       readOnlyCustomers: customers,
                                                       shouldDeleteExistingCustomers: pageNumber == 1,
                                                       in: self.sharedDerivedStorage) {
                    let hasNextPage = customers.count == pageSize
                    onCompletion(.success(hasNextPage))
                }
            case let .failure(error):
                onCompletion(.failure(error))
            }
        }
    }

    func deleteAllCustomers(from siteID: Int64, onCompletion: @escaping () -> Void) {
        sharedDerivedStorage.perform { [weak self] in
            self?.sharedDerivedStorage.deleteCustomers(siteID: siteID)
        }

        storageManager.saveDerivedType(derivedStorage: sharedDerivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
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
                                                  onCompletion: @escaping (Result<(), Error>) -> Void) {
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
                    onCompletion(.success(()))
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

    private func upsertCustomersAndSave(siteID: Int64,
                                 readOnlyCustomers: [StorageCustomerConvertible],
                                 shouldDeleteExistingCustomers: Bool = false,
                                 keyword: String? = nil,
                                 in storage: StorageType,
                                 onCompletion: @escaping () -> Void) {
        storage.perform { [weak self] in
            if shouldDeleteExistingCustomers {
                storage.deleteCustomers(siteID: siteID)
            }

            readOnlyCustomers.forEach {
                self?.upsertCustomer(siteID: siteID, readOnlyCustomer: $0, keyword: keyword, in: storage)
            }
        }

        storageManager.saveDerivedType(derivedStorage: storage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    private func upsertWCAnalyticsCustomersAndSave(siteID: Int64,
                                                   readOnlyCustomers: [WCAnalyticsCustomer],
                                                   shouldDeleteExistingCustomers: Bool = false,
                                                   keyword: String? = nil,
                                                   in storage: StorageType,
                                                   onCompletion: @escaping () -> Void) {
        storage.perform { [weak self] in
            if shouldDeleteExistingCustomers {
                storage.deleteWCAnalyticsCustomers(siteID: siteID)
            }

            readOnlyCustomers.forEach {
                self?.upsertWCAnalyticsCustomer(siteID: siteID, readOnlyCustomer: $0, keyword: keyword, in: storage)
            }
        }

        storageManager.saveDerivedType(derivedStorage: storage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Inserts or updates Customer entities into Storage
    ///
    private func upsertCustomer(siteID: Int64, readOnlyCustomer: StorageCustomerConvertible, keyword: String? = nil, in storage: StorageType) {
        let storageCustomer: Storage.Customer = {
            // If the specific customerID for that siteID already exists, return it
            // If doesn't or the user is unregistered (loadingID == 0), insert a new one in Storage
            // Since we reset the customers everytime we request them, there's no risk of having duplicated unregistered customers
            if readOnlyCustomer.loadingID != 0,
                let storedCustomer = storage.loadCustomer(siteID: siteID, customerID: readOnlyCustomer.loadingID) {
                return storedCustomer
            } else {
                return storage.insertNewObject(ofType: Storage.Customer.self)
            }
        }()

        if let keyword = keyword {
            let storedSearchResult = self.sharedDerivedStorage.loadCustomerSearchResult(siteID: siteID, keyword: keyword) ??
            self.sharedDerivedStorage.insertNewObject(ofType: Storage.CustomerSearchResult.self)

            storedSearchResult.siteID = siteID
            storedSearchResult.keyword = keyword

            storedSearchResult.addToCustomers(storageCustomer)
        }

        storageCustomer.update(with: readOnlyCustomer)
    }

    /// Inserts or update WCAnalyticsCustomer entities into Storage
    ///
    private func upsertWCAnalyticsCustomer(siteID: Int64, readOnlyCustomer: WCAnalyticsCustomer, keyword: String? = nil, in storage: StorageType) {
        let storageCustomer: Storage.WCAnalyticsCustomer = {
            if let storedCustomer = storage.loadWCAnalyticsCustomer(siteID: siteID, customerID: readOnlyCustomer.customerID) {
                return storedCustomer
            } else {
                return storage.insertNewObject(ofType: Storage.WCAnalyticsCustomer.self)
            }
        }()

        if let keyword {
            let storedSearchResult = self.sharedDerivedStorage
                .loadWCAnalyticsCustomerSearchResult(siteID: siteID, keyword: keyword) ??
            self.sharedDerivedStorage.insertNewObject(ofType: Storage.WCAnalyticsCustomerSearchResult.self)

            storedSearchResult.siteID = siteID
            storedSearchResult.keyword = keyword

            storedSearchResult.addToCustomers(storageCustomer)
        }

        storageCustomer.update(with: readOnlyCustomer)
    }
}
