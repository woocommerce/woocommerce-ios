import Foundation
import Networking
import Storage
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

public protocol PointOfSaleSettingsServiceProtocol {
    func retrievePointOfSaleSettings() async throws -> POSReceiptInformation
    func updatePointOfSaleSettings(_ changes: [POSReceiptField: String]) async throws -> POSReceiptInformation
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
                            selectedSite: AnyPublisher<JetpackSite?, Never>,
                            appPasswordSupportState: AnyPublisher<Bool, Never>,
                            storage: StorageManagerType) {
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.init(siteID: siteID, settingStoreMethods: SettingStoreMethods(storageManager: storage,
                                                                           network: network))
    }

    public func retrievePointOfSaleSettings() async throws -> POSReceiptInformation {
        let siteSettings = try await settingStoreMethods.retrievePointOfSaleSettings(siteID: siteID)
        return POSReceiptInformation(
            storeName: settingValue(from: siteSettings, settingID: POSReceiptField.storeName.rawValue),
            storeAddress: settingValue(from: siteSettings, settingID: POSReceiptField.storeAddress.rawValue),
            phone: settingValue(from: siteSettings, settingID: POSReceiptField.phone.rawValue),
            email: settingValue(from: siteSettings, settingID: POSReceiptField.email.rawValue),
            refundReturnsPolicy: settingValue(from: siteSettings, settingID: POSReceiptField.refundReturnsPolicy.rawValue)
        )
    }

    public func updatePointOfSaleSettings(_ changes: [POSReceiptField: String]) async throws -> POSReceiptInformation {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (field, value) in changes {
                group.addTask {
                    _ = try await self.settingStoreMethods.updatePointOfSaleSetting(
                        siteID: self.siteID,
                        settingID: field.rawValue,
                        value: value
                    )
                }
            }
            try await group.waitForAll()
        }
        return try await retrievePointOfSaleSettings()
    }

    private func settingValue(from siteSettings: [SiteSetting], settingID: String) -> String? {
        let value = siteSettings.first { $0.settingID == settingID }?.value
        return value?.isEmpty == true ? nil : value
    }
}
