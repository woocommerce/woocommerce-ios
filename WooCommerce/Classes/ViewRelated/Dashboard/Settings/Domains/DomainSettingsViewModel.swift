import Foundation
import Yosemite

/// View model for `DomainSettingsView`.
final class DomainSettingsViewModel: ObservableObject {
    struct Domain: Equatable {
        /// Whether the domain is the site's primary domain.
        let isPrimary: Bool

        /// The address of the domain.
        let name: String

        // The next renewal date.
        let autoRenewalDate: Date?
    }

    struct FreeStagingDomain: Equatable {
        /// Whether the domain is the site's primary domain.
        let isPrimary: Bool

        /// The address of the domain.
        let name: String
    }

    @Published private(set) var hasDomainCredit: Bool = false
    @Published private(set) var domains: [Domain] = []
    @Published private(set) var freeStagingDomain: FreeStagingDomain?

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    @MainActor
    func onAppear() async {
        async let domainsResult = loadDomains()
        async let siteCurrentPlanResult = loadSiteCurrentPlan()
        handleDomainsResult(await domainsResult)
        handleSiteCurrentPlanResult(await siteCurrentPlanResult)
    }
}

private extension DomainSettingsViewModel {
    @MainActor
    func loadDomains() async -> Result<[SiteDomain], Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(DomainAction.loadDomains(siteID: siteID) { result in
                continuation.resume(returning: result)
            })
        }
    }

    @MainActor
    func loadSiteCurrentPlan() async -> Result<WPComSitePlan, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(PaymentAction.loadSiteCurrentPlan(siteID: siteID) { result in
                continuation.resume(returning: result)
            })
        }
    }
}

private extension DomainSettingsViewModel {
    @MainActor
    func handleDomainsResult(_ result: Result<[SiteDomain], Error>) {
        switch result {
        case .success(let domains):
            let stagingDomain = domains.first(where: { $0.isWPCOMStagingDomain || $0.type == .wpcom })
            freeStagingDomain = stagingDomain
                .map { FreeStagingDomain(isPrimary: $0.isPrimary, name: $0.name) }
            self.domains = domains.filter { $0 != stagingDomain && $0.type != .wpcom }
                .map { Domain(isPrimary: $0.isPrimary, name: $0.name, autoRenewalDate: $0.renewalDate) }
        case .failure(let error):
            DDLogError("⛔️ Error retrieving domains for siteID \(siteID): \(error)")
        }
    }

    @MainActor
    func handleSiteCurrentPlanResult(_ result: Result<WPComSitePlan, Error>) {
        switch result {
        case .success(let sitePlan):
            hasDomainCredit = sitePlan.hasDomainCredit
        case .failure(let error):
            DDLogError("⛔️ Error retrieving site plan for siteID \(siteID): \(error)")
        }
    }
}
