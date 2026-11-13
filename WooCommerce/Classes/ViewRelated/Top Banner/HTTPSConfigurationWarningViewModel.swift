import Combine
import Foundation
import Yosemite

/// Determines when to warn a merchant that their store is configured with an HTTP URL.
@MainActor
final class HTTPSConfigurationWarningViewModel: ObservableObject {
    @Published private(set) var isVisible = false

    private let stores: StoresManager
    private let currentDate: () -> Date
    private var currentSiteID: Int64?

    init(stores: StoresManager = ServiceLocator.stores,
         currentDate: @escaping () -> Date = Date.init) {
        self.stores = stores
        self.currentDate = currentDate
    }

    func update(site: Site, fallbackSiteAddress: String?) {
        currentSiteID = site.siteID

        if let requiresUpdate = site.wasURLNormalizedToHTTPS {
            stores.dispatch(AppSettingsAction.setHTTPSConfigurationUpdateRequired(siteID: site.siteID,
                                                                                  required: requiresUpdate))
        }

        let fallbackAddressUsesHTTP = fallbackSiteAddress
            .flatMap { URL(string: $0)?.scheme?.lowercased() }
            .map { $0 == "http" } ?? false
        let detectedRequirement = site.wasURLNormalizedToHTTPS

        stores.dispatch(AppSettingsAction.getHTTPSConfigurationWarningState(siteID: site.siteID) { [weak self] storedRequirement, lastDismissedDate in
            guard let self, self.currentSiteID == site.siteID else {
                return
            }

            let requiresUpdate = detectedRequirement ?? storedRequirement ?? fallbackAddressUsesHTTP
            self.isVisible = requiresUpdate && !self.wasDismissedWithinLastDay(lastDismissedDate)
        })
    }

    func dismiss() {
        guard let currentSiteID else {
            return
        }
        stores.dispatch(AppSettingsAction.dismissHTTPSConfigurationWarning(siteID: currentSiteID, time: currentDate()))
        isVisible = false
    }
}

private extension HTTPSConfigurationWarningViewModel {
    func wasDismissedWithinLastDay(_ date: Date?) -> Bool {
        guard let date else {
            return false
        }
        return currentDate().timeIntervalSince(date) < Constants.dismissalDuration
    }

    enum Constants {
        static let dismissalDuration: TimeInterval = 24 * 60 * 60
    }
}
