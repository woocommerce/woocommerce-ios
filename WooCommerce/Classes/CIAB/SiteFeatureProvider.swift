import Combine
import Yosemite

/// Owns the lifecycle of site-type-resolved providers and publishes updates
/// on site switch.
///
/// Stored on `ServiceLocator` — replaces `ciabEligibilityChecker` after
/// migration is complete.
///
/// Synchronous providers (`current`) update immediately on site switch.
/// Tab-related providers will be added in a later phase.
///
final class SiteFeatureProvider {
    /// Synchronous providers — always up-to-date, no transition gap.
    @Published private(set) var current: SiteFeatureProviders

    private var cancellables = Set<AnyCancellable>()

    init(stores: StoresManager = ServiceLocator.stores) {
        let initialSite: Yosemite.Site? = nil
        self.current = SiteFeatureFactory.makeProviders(for: initialSite)

        stores.site
            .removeDuplicates()
            .sink { [weak self] site in
                guard let self else { return }
                self.current = SiteFeatureFactory.makeProviders(for: site)
            }
            .store(in: &cancellables)
    }
}
