import Foundation
import Combine
import struct Yosemite.SiteSetting
import enum Yosemite.Plugin
import struct Yosemite.SystemPlugin
import protocol Yosemite.PluginsServiceProtocol
import protocol Yosemite.PointOfSaleSettingsServiceProtocol
import struct Yosemite.POSReceiptInformation
import Observation
import protocol Storage.GRDBManagerProtocol
import protocol Yosemite.POSCatalogSyncCoordinatorProtocol
import class Yosemite.POSCatalogSettingsService

protocol PointOfSaleSettingsControllerProtocol {
    var connectedCardReader: CardPresentPaymentCardReader? { get }
    var storeViewModel: POSSettingsStoreViewModel { get }
    var localCatalogViewModel: POSSettingsLocalCatalogViewModel? { get }
}

@Observable final class PointOfSaleSettingsController: PointOfSaleSettingsControllerProtocol {
    private(set) var connectedCardReader: CardPresentPaymentCardReader?
    private var cancellables: AnyCancellable?

    let storeViewModel: POSSettingsStoreViewModel
    let localCatalogViewModel: POSSettingsLocalCatalogViewModel?

    init(siteID: Int64,
         settingsService: PointOfSaleSettingsServiceProtocol,
         cardPresentPaymentService: CardPresentPaymentFacade,
         pluginsService: PluginsServiceProtocol,
         defaultSiteName: String?,
         siteSettings: [SiteSetting],
         grdbManager: GRDBManagerProtocol,
         catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol?) {
        self.storeViewModel = POSSettingsStoreViewModel(siteID: siteID,
                                                        settingsService: settingsService,
                                                        pluginsService: pluginsService,
                                                        defaultSiteName: defaultSiteName,
                                                        siteSettings: siteSettings)
        if let catalogSyncCoordinator {
            self.localCatalogViewModel = POSSettingsLocalCatalogViewModel(
                siteID: siteID,
                catalogSettingsService: POSCatalogSettingsService(grdbManager: grdbManager),
                catalogSyncCoordinator: catalogSyncCoordinator
            )
        } else {
            self.localCatalogViewModel = nil
        }

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
}

#if DEBUG
final class PointOfSaleSettingsPreviewController: PointOfSaleSettingsControllerProtocol {
    var connectedCardReader: CardPresentPaymentCardReader? = CardPresentPaymentCardReader(
        name: "WisePad 3",
        batteryLevel: 0.75
    )

    var storeViewModel: POSSettingsStoreViewModel = POSSettingsStoreViewModel(siteID: 123,
                                                                              settingsService: MockPointOfSaleSettingsService(),
                                                                              pluginsService: PluginsServicePreview(),
                                                                              defaultSiteName: "Sample Store",
                                                                              siteSettings: [])

    var localCatalogViewModel: POSSettingsLocalCatalogViewModel?
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
