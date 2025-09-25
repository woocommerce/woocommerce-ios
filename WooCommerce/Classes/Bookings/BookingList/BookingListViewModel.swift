import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `BookingListView`
final class BookingListViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager
    private let storage: StorageManagerType
    
    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.stores = stores
        self.storage = storage
    }
}

