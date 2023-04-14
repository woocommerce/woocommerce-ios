import Foundation
import Yosemite
import Combine

/// Type that fetches and shares a `WPCom` store plan(subscription).
/// The plan is stored on memory and not on the Storage Layer because this only relates to `WPCom` stores.
///
final class StorePlanSynchronizer: ObservableObject {

    /// Dependency state.
    ///
    enum PlanState: Equatable {
        case notLoaded
        case loading
        case loaded(WPComSitePlan)
    }

    /// Current synced plan.
    ///
    @Published private(set) var planState = PlanState.notLoaded

    /// Current logged-in site. `Nil` if not logged-in.
    ///
    private var site: Site?

    /// Stores manager.
    ///
    private let stores: StoresManager

    /// Observable subscription store.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores

        stores.site.sink { [weak self] site in
            guard let self else { return }
            self.site = site
            self.reloadPlan()
        }
        .store(in: &subscriptions)
    }

    /// Loads the plan from network
    ///
    func reloadPlan() {
        // If there is no logged-in site or the site is not a WPCom site, set the plan to `.notLoaded`
        guard let siteID = site?.siteID, site?.isWordPressComStore == true else {
            planState = .notLoaded
            return
        }

        // Do not fetch the plan if the plan it is already being loaded.
        guard planState != .loading else { return }

        planState = .loading
        let action = PaymentAction.loadSiteCurrentPlan(siteID: siteID) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let plan):
                self.planState = .loaded(plan)
            case .failure(let error):
                self.planState = .notLoaded
                DDLogError("⛔️ Error synchronizing WPCom plan: \(error)")
            }
        }
        stores.dispatch(action)
    }
}
