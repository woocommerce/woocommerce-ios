import Foundation
import UIKit
import Yosemite
import protocol WooFoundation.Analytics
import protocol Experiments.FeatureFlagService
import enum Networking.RemoteFeatureFlag
import enum WooFoundation.CountryCode

/// Provides client-side promotional banners for stores that cannot receive server-side JITMs.
@MainActor
final class ClientSideBannerProvider {

    private let stores: StoresManager
    private let analytics: Analytics
    private let featureFlagService: FeatureFlagService
    private let siteSettings: SelectedSiteSettingsProtocol
    private let userInterfaceIdiom: UIUserInterfaceIdiom

    init(stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         siteSettings: SelectedSiteSettingsProtocol = ServiceLocator.selectedSiteSettings,
         userInterfaceIdiom: UIUserInterfaceIdiom) {
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.siteSettings = siteSettings
        self.userInterfaceIdiom = userInterfaceIdiom
    }

    /// Returns a banner view model if the store is eligible for client-side banners.
    /// - Parameter site: The current site to check eligibility for.
    /// - Returns: A `FeatureAnnouncementCardViewModel` if eligible, `nil` otherwise.
    func loadBanner(for site: Site) async -> FeatureAnnouncementCardViewModel? {
        // POS promo is only shown on phones
        guard userInterfaceIdiom == .phone else {
            return nil
        }

        guard isNonJetpackSite(site) else {
            return nil
        }

        guard featureFlagService.isFeatureFlagEnabled(.clientSideDashboardBanner) else {
            return nil
        }

        let isRemoteFlagEnabled = await isRemoteFeatureFlagEnabled()
        guard isRemoteFlagEnabled else {
            return nil
        }

        // Check dismissal before potentially slow operations
        let campaign = POSPromoOnPhonesCampaign()
        guard await isBannerVisible(for: campaign.configuration.campaign) else {
            return nil
        }

        guard await isEligibleCountry(siteID: site.siteID) else {
            return nil
        }

        return FeatureAnnouncementCardViewModel(
            analytics: analytics,
            configuration: campaign.configuration,
            stores: stores
        )
    }

    private func isNonJetpackSite(_ site: Site) -> Bool {
        let connectionType = SiteConnectionType(site: site)
        return connectionType == .nonJetpack
    }

    private func isRemoteFeatureFlagEnabled() async -> Bool {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume(returning: false)
            }
            let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(
                .wooPosTabletPromoBanner,
                defaultValue: false
            ) { isEnabled in
                continuation.resume(returning: isEnabled)
            }
            self.stores.dispatch(action)
        }
    }

    private func isBannerVisible(for campaign: FeatureAnnouncementCampaign) async -> Bool {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume(returning: false)
            }
            let action = AppSettingsAction.getFeatureAnnouncementVisibility(campaign: campaign) { result in
                switch result {
                case .success(let isVisible):
                    continuation.resume(returning: isVisible)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
            self.stores.dispatch(action)
        }
    }

    private func isEligibleCountry(siteID: Int64?) async -> Bool {
        guard let siteID else {
            return false
        }

        let currentSettings = siteSettings.siteSettings
        if currentSettings.isNotEmpty {
            let countryCode = SiteAddress(siteSettings: currentSettings).countryCode
            return countryCode == .US || countryCode == .GB
        }

        // Wait for settings with a timeout
        let settings = await waitForSiteSettings(siteID: siteID)
        guard settings.isNotEmpty else {
            return false
        }

        let countryCode = SiteAddress(siteSettings: settings).countryCode
        return countryCode == .US || countryCode == .GB
    }

    private func waitForSiteSettings(siteID: Int64) async -> [SiteSetting] {
        let settingsTask = Task { () -> [SiteSetting] in
            for await settingsUpdate in siteSettings.settingsStream.values {
                guard settingsUpdate.siteID == siteID,
                      settingsUpdate.settings.isNotEmpty else {
                    continue
                }
                return settingsUpdate.settings
            }
            return []
        }

        let timeoutTask = Task { () -> [SiteSetting] in
            try? await Task.sleep(nanoseconds: 10 * NSEC_PER_SEC)
            return []
        }

        return await withTaskGroup(of: [SiteSetting].self) { group in
            group.addTask { await settingsTask.value }
            group.addTask { await timeoutTask.value }

            if let result = await group.next() {
                group.cancelAll()
                return result
            }
            return []
        }
    }
}
