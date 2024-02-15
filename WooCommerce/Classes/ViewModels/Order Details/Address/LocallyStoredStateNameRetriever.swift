import Foundation
import Yosemite
import Storage

/// Retrieves the locally stored state name of an address.
///
final class LocallyStoredStateNameRetriever {
    private let storageManager: StorageManagerType

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.viewStorage
    }()

    init(storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.storageManager = storageManager
    }

    /// Retrieves the locally stored state name of the given address.
    ///
    ///  - Parameter address: The passed address. The function assumes that the state value is a code.
    ///  - Returns: The retrieved state name, or `nil` if none be retrieved.
    ///
    func retrieveLocallyStoredStateName(of address: Address) -> String? {
        retrieveLocallyStoredStateName(for: address.state, countryCode: address.country)
    }
}

private extension LocallyStoredStateNameRetriever {
    func retrieveLocallyStoredStateName(for stateCode: String, countryCode: String) -> String? {
        let codePredicate = NSPredicate(format: "code LIKE[c] %@", stateCode)
        let countryPredicate = NSPredicate(format: "relationship.code LIKE[c] %@", countryCode)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [codePredicate, countryPredicate])

        let results = sharedDerivedStorage.allObjects(ofType: Storage.StateOfACountry.self,
                                                      matching: predicate,
                                                      sortedBy: nil)
        return results.first?.name
    }
}
