import Foundation
import Networking
import Storage

// MARK: - CustomerStore
//
public class CustomerStore: Store {
    private let remote: CustomerRemote

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = CustomerRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: CustomerAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? CustomerAction else {
            assertionFailure("CustomerStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeAllCustomers(let siteID, let completion):
            synchronizeAllCustomers(siteID: siteID, completion: completion)
        }
    }
}

// MARK: - Services
//
private extension CustomerStore {

    /// Retrieves all of the customers associated with a given Site ID (if any!).
    ///
    func synchronizeAllCustomers(siteID: Int64, fromPageNumber: Int = CustomerRemote.Default.pageNumber, completion: @escaping (Result<Void, Error>) -> Void) {
        synchronizeCustomersPage(siteID: siteID, pageNumber: fromPageNumber, pageSize: CustomerRemote.Default.pageSize) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                if response.isEmpty {
                    completion(.success(()))
                } else {
                    self.synchronizeAllCustomers(siteID: siteID, fromPageNumber: fromPageNumber + 1, completion: completion)
                }
            }
        }
    }

    /// Retrieves single page of the customers associated with a given Site ID (if any!).
    ///
    func synchronizeCustomersPage(siteID: Int64, pageNumber: Int, pageSize: Int, completion: @escaping (Result<[Customer], Error>) -> Void) {
        remote.getAllCustomers(for: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }

            if pageNumber == CustomerRemote.Default.pageNumber {
                self.deleteStoredCustomers(siteID: siteID)
            }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                self.upsertCustomersInBackground(siteID: siteID, customers: response) {
                    completion(.success(response))
                }
            }
        }
    }
}

// MARK: - Storage
//
private extension CustomerStore {

    /// Deletes all of the stored Customers for the provided siteID.
    func deleteStoredCustomers(siteID: Int64) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.deleteCustomers(siteID: siteID)
        derivedStorage.saveIfNeeded()
    }

    /// Updates/inserts the specified readonly Customer entities *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    func upsertCustomersInBackground(siteID: Int64,
                                     customers: [Customer],
                                     onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            guard let self = self else { return }
            guard customers.isEmpty == false else {
                return
            }

            self.upsertCustomers(siteID: siteID, customers: customers)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates/inserts the specified readonly Customer entities in the current thread.
    func upsertCustomers(siteID: Int64, customers: [Customer]) {
        let derivedStorage = sharedDerivedStorage

        for readOnlyCustomer in customers {
            let storageCustomer = derivedStorage.insertNewObject(ofType: Storage.Customer.self)
            storageCustomer.update(with: readOnlyCustomer)
        }
    }
}
