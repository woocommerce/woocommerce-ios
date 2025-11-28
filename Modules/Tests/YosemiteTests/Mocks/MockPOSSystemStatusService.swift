import Foundation
import Networking
@testable import Yosemite

final class MockPOSSystemStatusService: POSSystemStatusServiceProtocol {
    var pluginInfoToReturn: Result<POSPluginAndFeatureInfo, Error>
    var loadPluginCallCount = 0
    var lastCheckedSiteID: Int64?

    init(pluginInfoToReturn: Result<POSPluginAndFeatureInfo, Error> = .success(
        POSPluginAndFeatureInfo(
            wcPlugin: SystemPlugin(
                siteID: 123,
                plugin: "woocommerce/woocommerce.php",
                name: "WooCommerce",
                version: "10.3.0",
                versionLatest: "10.3.0",
                url: "https://woocommerce.com",
                authorName: "WooCommerce",
                authorUrl: "https://woocommerce.com",
                networkActivated: false,
                active: true
            ),
            featureValue: true
        )
    )) {
        self.pluginInfoToReturn = pluginInfoToReturn
    }

    func loadWooCommercePluginAndPOSFeatureSwitch(siteID: Int64) async throws -> POSPluginAndFeatureInfo {
        loadPluginCallCount += 1
        lastCheckedSiteID = siteID
        switch pluginInfoToReturn {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        }
    }
}
