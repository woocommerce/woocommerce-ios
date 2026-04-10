import Foundation
import Yosemite
import Storage
import Experiments
import PointOfSale
import class WooFoundation.VersionHelpers

struct POSSunsetWarningChecker: POSSunsetWarningChecking {
    private let featureFlagService: FeatureFlagService
    private let systemStatusService: POSSystemStatusServiceProtocol
    private let siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol
    private let currentDate: () -> Date

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         systemStatusService: POSSystemStatusServiceProtocol,
         siteSettings: SiteSpecificAppSettingsStoreMethodsProtocol = SiteSpecificAppSettingsStoreMethods(fileStorage: PListFileStorage()),
         currentDate: @escaping () -> Date = { Date() }) {
        self.featureFlagService = featureFlagService
        self.systemStatusService = systemStatusService
        self.siteSettings = siteSettings
        self.currentDate = currentDate
    }

    func shouldShowSunsetWarning(siteID: Int64) async -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleCatalogAPI) else {
            return false
        }

        if let lastDismissedDate = siteSettings.getSunsetWarningLastDismissedDate(siteID: siteID) {
            let daysSinceDismissal = Calendar.current.dateComponents([.day], from: lastDismissedDate, to: currentDate()).day ?? 0
            if daysSinceDismissal < Constants.dismissalThresholdDays {
                return false
            }
        }

        do {
            let pluginInfo = try await systemStatusService.loadWooCommercePluginAndPOSFeatureSwitch(siteID: siteID)
            guard let wcPlugin = pluginInfo.wcPlugin, wcPlugin.active else {
                return false
            }
            return !VersionHelpers.isVersionSupported(
                version: wcPlugin.version,
                minimumRequired: Constants.minimumWCVersion
            )
        } catch {
            return false
        }
    }

    func recordDismissal(siteID: Int64) {
        siteSettings.setSunsetWarningLastDismissedDate(siteID: siteID, date: currentDate())
    }
}

private extension POSSunsetWarningChecker {
    enum Constants {
        static let dismissalThresholdDays = 14
        static let minimumWCVersion = "10.5.0"
    }
}
