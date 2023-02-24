import Foundation
import Yosemite

/// View model for `JetpackBenefitsView`
///
final class JetpackBenefitsViewModel {
    /// Whether the view is showing benefits for a JetpackCP site or non-Jetpack site.
    let isJetpackCPSite: Bool
    private let stores: StoresManager

    init(isJetpackCPSite: Bool, stores: StoresManager = ServiceLocator.stores) {
        self.isJetpackCPSite = isJetpackCPSite
        self.stores = stores
    }

    @MainActor
    func fetchJetpackUser() async -> Result<JetpackUser, Error> {
        guard !isJetpackCPSite else {
            return .failure(FetchJetpackUserError.notSupportedForJCPSites)
        }
        return await withCheckedContinuation { continuation in
            let action = JetpackConnectionAction.fetchJetpackUser { result in
                continuation.resume(returning: result)
            }
            stores.dispatch(action)
        }
    }
}

extension JetpackBenefitsViewModel {
    enum FetchJetpackUserError: Error, Equatable {
        case notSupportedForJCPSites
    }
}
