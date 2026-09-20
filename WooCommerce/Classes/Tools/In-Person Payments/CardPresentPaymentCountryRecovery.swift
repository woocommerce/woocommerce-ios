import Combine
import Foundation
import Yosemite

/// Keeps payment entry points current when general settings arrive after the screen was created.
/// Settings observations and action completions are delivered on the main queue.
final class CardPresentPaymentCountryRecovery: ObservableObject {
    @Published private(set) var configuration: CardPresentPaymentsConfiguration
    @Published private(set) var isLoading = false
    @Published private(set) var notice: PermanentNotice?

    private let siteID: Int64
    private let stores: StoresManager
    private let settings: SelectedSiteSettingsProtocol
    private var hasAttemptedRecovery = false
    private var settingsSubscription: AnyCancellable?

    init(siteID: Int64,
         configuration: CardPresentPaymentsConfiguration,
         stores: StoresManager,
         settings: SelectedSiteSettingsProtocol) {
        self.siteID = siteID
        self.configuration = configuration
        self.stores = stores
        self.settings = settings
        settingsSubscription = settings.settingsStream
            .filter { $0.siteID == siteID }
            .sink { [weak self] update in
                self?.updateConfiguration(settings: update.settings)
            }
    }

    func recoverIfNeeded() {
        guard !hasAttemptedRecovery else { return }
        retry()
    }

    func retry() {
        guard configuration.countryCode == .unknown,
              !isLoading,
              stores.sessionManager.defaultStoreID == siteID else { return }
        hasAttemptedRecovery = true
        isLoading = true
        notice = nil
        stores.dispatch(SettingAction.synchronizeGeneralSiteSettings(siteID: siteID) { [weak self] error in
            guard let self else { return }
            isLoading = false
            guard stores.sessionManager.defaultStoreID == siteID else { return }
            if let error {
                DDLogError("⛔️ Recovering payment country failed for siteID \(siteID): \(error)")
            }
            settings.refresh()
            updateConfiguration(settings: settings.siteSettings)
            if configuration.countryCode == .unknown {
                notice = PermanentNotice(message: error == nil ? Localization.countryUnavailable : Localization.settingsUnavailable,
                                         callToActionTitle: Localization.retry,
                                         callToActionHandler: { [weak self] in self?.retry() })
            }
        })
    }

    private func updateConfiguration(settings: [SiteSetting]) {
        let updated = CardPresentPaymentsConfiguration(country: SiteAddress(siteSettings: settings).countryCode)
        if updated != configuration {
            configuration = updated
        }
        if updated.countryCode != .unknown {
            notice = nil
        }
    }

    enum Localization {
        static let loading = NSLocalizedString("cardPresentPayment.countryRecovery.loading",
                                               value: "Checking in-person payment availability…",
                                               comment: "Status while fetching store settings to check in-person payment availability.")
        static let settingsUnavailable = NSLocalizedString("cardPresentPayment.countryRecovery.settingsUnavailable",
                                                           value: "We couldn’t load your store settings to check in-person payment availability.",
                                                           comment: "Shown when fetching store settings fails and the store country remains unknown.")
        static let countryUnavailable = NSLocalizedString(
            "cardPresentPayment.countryRecovery.countryUnavailable",
            value: "We couldn’t identify your store’s country. Check the country in your WooCommerce store settings.",
            comment: "Shown when fetched store settings have no recognizable country. Check the store country, then retry.")
        static let retry = NSLocalizedString("cardPresentPayment.countryRecovery.retry",
                                             value: "Retry",
                                             comment: "Retry fetching store settings to check in-person payment availability.")
    }
}
