import Foundation
import Networking
import Storage

public protocol PointOfSaleSettingsServiceProtocol {
    var siteID: Int64 { get }
    func retrievePointOfSaleSettings() async throws -> [SiteSetting]
}

public final class PointOfSaleSettingsService: PointOfSaleSettingsServiceProtocol {
    public let siteID: Int64
    private let settingStoreMethods: SettingStoreMethodsProtocol

    init(siteID: Int64,
         settingStoreMethods: SettingStoreMethodsProtocol) {
        self.siteID = siteID
        self.settingStoreMethods = settingStoreMethods
    }

    public convenience init(siteID: Int64,
                            credentials: Credentials?,
                            storage: StorageManagerType) {
        let network = AlamofireNetwork(credentials: credentials)
        self.init(siteID: siteID, settingStoreMethods: SettingStoreMethods(storageManager: storage,
                                                                           network: network))
    }

    public func retrievePointOfSaleSettings() async throws -> [SiteSetting] {
        return try await settingStoreMethods.retrievePointOfSaleSettings(siteID: siteID)
    }
}
