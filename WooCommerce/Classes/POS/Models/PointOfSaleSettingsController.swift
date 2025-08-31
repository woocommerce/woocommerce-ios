import Foundation
import Combine
import struct Yosemite.SiteSetting
import enum Yosemite.Plugin
import struct Yosemite.SystemPlugin
import protocol Yosemite.PluginsServiceProtocol
import protocol Yosemite.PointOfSaleSettingsServiceProtocol
import struct Yosemite.POSReceiptInformation
import Observation

protocol PointOfSaleSettingsControllerProtocol {
    var storeName: String { get }
    var storeAddress: String { get }
    var connectedCardReader: CardPresentPaymentCardReader? { get }
    var storeViewModel: POSSettingsStoreViewModel { get }
}

@Observable final class PointOfSaleSettingsController: PointOfSaleSettingsControllerProtocol {
    let siteID: Int64
    let settingsService: PointOfSaleSettingsServiceProtocol
    let pluginsService: PluginsServiceProtocol

    private let defaultSiteName: String?
    private let siteSettings: [SiteSetting]
    private(set) var connectedCardReader: CardPresentPaymentCardReader?
    private var cancellables: AnyCancellable?

    let storeViewModel: POSSettingsStoreViewModel

    init(siteID: Int64,
         settingsService: PointOfSaleSettingsServiceProtocol,
         cardPresentPaymentService: CardPresentPaymentFacade,
         pluginsService: PluginsServiceProtocol,
         defaultSiteName: String? = ServiceLocator.stores.sessionManager.defaultSite?.name,
         siteSettings: [SiteSetting] = ServiceLocator.selectedSiteSettings.siteSettings) {
        self.siteID = siteID
        self.settingsService = settingsService
        self.pluginsService = pluginsService
        self.defaultSiteName = defaultSiteName
        self.siteSettings = siteSettings
        self.storeViewModel = POSSettingsStoreViewModel(siteID: siteID,
                                                        settingsService: settingsService,
                                                        pluginsService: pluginsService,
                                                        defaultSiteName: defaultSiteName,
                                                        siteSettings: siteSettings)

        observeCardReader(from: cardPresentPaymentService)
    }

    private func observeCardReader(from service: CardPresentPaymentFacade) {
        cancellables = service.readerConnectionStatusPublisher
            .sink(receiveValue: { [weak self] connectionStatus in
                guard let self else { return }
                let cardReader: CardPresentPaymentCardReader?
                switch connectionStatus {
                case .connected(let reader):
                    cardReader = reader
                default:
                    cardReader = nil
                }
                connectedCardReader = cardReader
            })
    }

    var storeName: String {
        if let defaultSiteName {
            return defaultSiteName
        } else {
            return Localization.storeNameNotSet
        }
    }

    var storeAddress: String {
        SiteAddress(siteSettings: siteSettings).address
    }

}

private extension PointOfSaleSettingsController {
    enum Localization {
        static let storeNameNotSet = NSLocalizedString(
            "pointOfSaleSettingsService.storeNameNotSet",
            value: "Not set",
            comment: "Text displayed on Point of Sale settings when store has not been provided."
        )
    }
}

#if DEBUG
final class PointOfSaleSettingsPreviewController: PointOfSaleSettingsControllerProtocol {
    var storeName: String = "Sample Store"
    var connectedCardReader: CardPresentPaymentCardReader? = CardPresentPaymentCardReader(
        name: "WisePad 3",
        batteryLevel: 0.75
    )

    var storeAddress: String {
        "123 Main Street\nAnytown, ST 12345"
    }

    var storeViewModel: POSSettingsStoreViewModel = POSSettingsStoreViewModel(siteID: 123,
                                                                              settingsService: MockPointOfSaleSettingsService(),
                                                                              pluginsService: PluginsServicePreview(),
                                                                              defaultSiteName: "Sample Store",
                                                                              siteSettings: [])
}

final class MockPointOfSaleSettingsService: PointOfSaleSettingsServiceProtocol {
    func retrievePointOfSaleSettings() async throws -> POSReceiptInformation {
        return .empty
    }
}

final class PluginsServicePreview: PluginsServiceProtocol {
    func waitForPluginInStorage(siteID: Int64, pluginPath: String, isActive: Bool) async -> SystemPlugin {
        return SystemPlugin(siteID: 1234,
                            plugin: "",
                            name: "",
                            version: "",
                            versionLatest: "",
                            url: "",
                            authorName: "",
                            authorUrl: "",
                            networkActivated: false,
                            active: true)
    }

    func loadPluginInStorage(siteID: Int64, plugin: Plugin, isActive: Bool?) -> SystemPlugin? {
        return SystemPlugin(siteID: 1234,
                            plugin: "",
                            name: "",
                            version: "",
                            versionLatest: "",
                            url: "",
                            authorName: "",
                            authorUrl: "",
                            networkActivated: false,
                            active: true)
    }
}
#endif
