import Combine
import Yosemite

final class InPersonPaymentsViewModel: ObservableObject {
    @Published var state: CardPresentPaymentOnboardingState
    var userIsAdministrator: Bool
    var learnMoreURL: URL {
        get { return getLearnMoreUrl(state: state) }
    }
    private let useCase = CardPresentPaymentsOnboardingUseCase()


    /// Initializes the view model for a specific site
    ///
    init() {
        state = useCase.state
        userIsAdministrator = ServiceLocator.stores.sessionManager.defaultRoles.contains(.administrator)

        useCase.$state
            // Debounce values to prevent the loading screen flashing when there is no connection
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .handleEvents(receiveOutput: trackState(_:))
            .assign(to: &$state)
        refresh()
    }

    /// Initializes the view model with a fixed state that never changes.
    /// This is useful for SwiftUI previews or testing, but shouldn't be used in production
    ///
    init(fixedState: CardPresentPaymentOnboardingState, fixedUserIsAdministrator: Bool = false) {
        state = fixedState
        userIsAdministrator = fixedUserIsAdministrator
    }

    /// Synchronizes the required data from the server and recalculates the state
    ///
    func refresh() {
        useCase.refresh()
    }

    private func getLearnMoreUrl(state: CardPresentPaymentOnboardingState) -> URL {
        switch state {
        case .pluginUnsupportedVersion(let plugin),
                .pluginNotActivated(let plugin),
                .pluginInTestModeWithLiveStripeAccount(let plugin),
                .pluginSetupNotCompleted(let plugin),
                .countryNotSupportedStripe(let plugin, _),
                .stripeAccountUnderReview(let plugin),
                .stripeAccountPendingRequirement(let plugin, _),
                .stripeAccountOverdueRequirement(let plugin),
                .stripeAccountRejected(let plugin):
            return getLearnMoreUrl(plugin: plugin)
        default:
            return getLearnMoreUrl(plugin: nil)
        }
    }

    private func getLearnMoreUrl(plugin: CardPresentPaymentsPlugins?) -> URL {
        switch plugin {
            case .stripe:
                return WooConstants.URLs.inPersonPaymentsLearnMoreStripe.asURL()
            case .wcPay, nil:
                return WooConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL()
        }
    }
}

private func trackState(_ state: CardPresentPaymentOnboardingState) {
    guard let reason = state.reasonForAnalytics else {
        return
    }
    let properties = [
        "reason": reason
    ]
    ServiceLocator.analytics.track(.cardPresentOnboardingNotCompleted, withProperties: properties)
}
