import Foundation
import Networking
import Storage
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

public protocol PointOfSaleSettingsServiceProtocol {
    func retrievePointOfSaleSettings() async throws -> POSReceiptInformation
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
            storeName: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_name"),
            storeAddress: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_address"),
            phone: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_phone"),
            email: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_email"),
            refundReturnsPolicy: settingValue(from: siteSettings, settingID: "woocommerce_pos_refund_returns_policy")
        )
    }

    private func settingValue(from siteSettings: [SiteSetting], settingID: String) -> String? {
        let value = siteSettings.first { $0.settingID == settingID }?.value
        return value?.isEmpty == true ? nil : value
    }
}
