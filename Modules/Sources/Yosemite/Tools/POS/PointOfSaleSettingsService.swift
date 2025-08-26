import Foundation
import Networking
import Storage

public protocol PointOfSaleSettingsServiceProtocol {
    var siteID: Int64 { get }
    func retrievePointOfSaleSettings() async throws -> [SiteSetting]
}

public final class PointOfSaleSettingsService: PointOfSaleSettingsServiceProtocol {
    public private(set) var siteID: Int64
    private let settingStoreMethods: SettingStoreMethodsProtocol
    private let storage: StorageManagerType

    init(siteID: Int64,
         settingStoreMethods: SettingStoreMethodsProtocol,
         storage: StorageManagerType) {
        self.siteID = siteID
        self.settingStoreMethods = settingStoreMethods
        self.storage = storage
    }

    public convenience init(siteID: Int64,
                            credentials: Credentials?,
                            storage: StorageManagerType) {
        let network = AlamofireNetwork(credentials: credentials)
        self.init(siteID: siteID,
                  settingStoreMethods: SettingStoreMethods(storageManager: storage,
                                                           network: network),
                  storage: storage)
    }

    public func retrievePointOfSaleSettings() async throws -> [SiteSetting] {
        return try await settingStoreMethods.retrievePointOfSaleSettings(siteID: siteID)
    }
}
