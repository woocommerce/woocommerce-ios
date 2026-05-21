import Foundation
import protocol Yosemite.StoresManager
import struct Yosemite.SystemPlugin
import protocol Yosemite.POSSystemStatusServiceProtocol
import class Yosemite.POSSystemStatusService
import protocol Yosemite.POSSiteSettingServiceProtocol
import class Yosemite.POSSiteSettingService
import class WooFoundation.VersionHelpers
import protocol PointOfSale.POSEntryPointEligibilityCheckerProtocol
import enum PointOfSale.POSEligibilityState
import enum PointOfSale.POSIneligibleReason

final class POSTabEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    private let siteID: Int64
    private let stores: StoresManager
    private let systemStatusService: POSSystemStatusServiceProtocol
    private let siteSettingService: POSSiteSettingServiceProtocol
    private let appPasswordSupportState: ApplicationPasswordsExperimentState

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         systemStatusService: POSSystemStatusServiceProtocol? = nil,
         siteSettingService: POSSiteSettingServiceProtocol? = nil) {
        self.siteID = siteID
        self.stores = stores
        self.appPasswordSupportState = ApplicationPasswordsExperimentState()

        let credentials = stores.sessionManager.defaultCredentials
        let selectedSite = stores.sessionManager.defaultSitePublisher.map { $0?.toJetpackSite() }.eraseToAnyPublisher()
        let appPasswordSupport = appPasswordSupportState.$isAvailableAndEnabled.eraseToAnyPublisher()
        self.systemStatusService = systemStatusService ?? POSSystemStatusService(
            credentials: credentials,
            selectedSite: selectedSite,
            appPasswordSupportState: appPasswordSupport,
            storageManager: ServiceLocator.storageManager
        )
        self.siteSettingService = siteSettingService ?? POSSiteSettingService(
            credentials: credentials,
            selectedSite: selectedSite,
            appPasswordSupportState: appPasswordSupport
        )
    }

    /// Determines whether the POS entry point can be shown based on the WC plugin state.
    ///
    /// Country, currency, and the WC POS feature switch are no longer gated here —
    /// POS is available worldwide and the per-store opt-in is being removed for GA.
    /// The remaining check is plugin presence + minimum-version compatibility.
    func checkEligibility() async -> POSEligibilityState {
        // Bypass eligibility checks for screenshot tests
        if ProcessConfiguration.shouldBypassPOSEligibilityChecks {
            return .eligible
        }

        return await checkPluginEligibility()
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        switch ineligibleReason {
        case .unsupportedWooCommerceVersion, .wooCommercePluginNotFound:
            return await checkEligibility()
        case .selfDeallocated:
            return await checkEligibility()
        }
    }
}

// MARK: - WC Plugin Related Eligibility Check

private extension POSTabEligibilityChecker {
    /// Checks plugin presence and minimum-version compatibility.
    ///
    /// - Returns: The eligibility state for POS based on the WooCommerce plugin.
    func checkPluginEligibility() async -> POSEligibilityState {
        do {
            let info = try await systemStatusService.loadWooCommercePluginAndPOSFeatureSwitch(siteID: siteID)
            return checkWooCommercePluginEligibility(wcPlugin: info.wcPlugin)
        } catch {
            return .ineligible(reason: .wooCommercePluginNotFound)
        }
    }

    func checkWooCommercePluginEligibility(wcPlugin: SystemPlugin?) -> POSEligibilityState {
        guard let wcPlugin, wcPlugin.active else {
            return .ineligible(reason: .wooCommercePluginNotFound)
        }

        guard VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                minimumRequired: Constants.wcPluginMinimumVersion) else {
            return .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: Constants.wcPluginMinimumVersion))
        }

        return .eligible
    }
}

private extension POSTabEligibilityChecker {
    enum Constants {
        static let wcPlugin = "woocommerce/woocommerce.php"
        static let wcPluginMinimumVersion = "9.6.0-beta"
    }
}
