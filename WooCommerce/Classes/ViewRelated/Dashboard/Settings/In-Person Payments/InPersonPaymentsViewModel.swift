import Combine
import Yosemite
import Experiments

final class InPersonPaymentsViewModel: ObservableObject {
    @Published var state: CardPresentPaymentOnboardingState
    var userIsAdministrator: Bool
    var learnMoreURL: URL? = nil
    private let useCase: CardPresentPaymentsOnboardingUseCase
    let stores: StoresManager

    /// Initializes the view model for a specific site
    ///
    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         useCase: CardPresentPaymentsOnboardingUseCase = CardPresentPaymentsOnboardingUseCase()) {
        self.stores = stores
        self.useCase = useCase
        state = useCase.state
        userIsAdministrator = ServiceLocator.stores.sessionManager.defaultRoles.contains(.administrator)

        useCase.$state
            .share()
            // Debounce values to prevent the loading screen flashing when there is no connection
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] result in
                self?.updateLearnMoreURL(state: result)
            })
            .handleEvents(receiveOutput: trackState(_:))
            .assign(to: &$state)
    }

    /// Initializes the view model with a fixed state that never changes.
    /// This is useful for SwiftUI previews or testing, but shouldn't be used in production
    ///
    init(
        fixedState: CardPresentPaymentOnboardingState,
        fixedUserIsAdministrator: Bool = false,
        stores: StoresManager = ServiceLocator.stores) {
            self.stores = stores
            state = fixedState
            useCase = CardPresentPaymentsOnboardingUseCase()
            userIsAdministrator = fixedUserIsAdministrator
            updateLearnMoreURL(state: fixedState)
        }

    /// Synchronizes the required data from the server and recalculates the state
    ///
    func refresh() {
        useCase.refresh()
    }

    /// Skips the Pending Requirements step when the user taps `Skip`
    ///
    func skipPendingRequirements() {
        trackSkipped(state: useCase.state, remindLater: true)
        useCase.skipPendingRequirements()
    }

    /// Selects the plugin to use as a payment gateway when there are multiple available
    ///
    func selectPlugin(_ plugin: CardPresentPaymentsPlugin) {
        useCase.selectPlugin(plugin)
    }

    func clearPluginSelection() {
        useCase.clearPluginSelection()
    }

    private func updateLearnMoreURL(state: CardPresentPaymentOnboardingState) {
        let preferredPlugin: CardPresentPaymentsPlugin
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
            preferredPlugin = plugin
        default:
            preferredPlugin = .wcPay
        }

        learnMoreURL = { () -> URL in
            switch preferredPlugin {
            case .wcPay:
                return WooConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL()
            case .stripe:
                return WooConstants.URLs.inPersonPaymentsLearnMoreStripe.asURL()
            }
        }()
    }
}

private extension InPersonPaymentsViewModel {
    var countryCode: String {
        useCase.configurationLoader.configuration.countryCode
    }

    func trackState(_ state: CardPresentPaymentOnboardingState) {
        guard state.shouldTrackOnboardingStepEvents else {
            return
        }
        ServiceLocator.analytics
            .track(event: .InPersonPayments
                .cardPresentOnboardingNotCompleted(reason: state.reasonForAnalytics,
                                                   countryCode: countryCode))
    }

    func trackSkipped(state: CardPresentPaymentOnboardingState, remindLater: Bool) {
        guard state.shouldTrackOnboardingStepEvents else {
            return
        }

        ServiceLocator.analytics.track(
            event: .InPersonPayments.cardPresentOnboardingStepSkipped(
                reason: state.reasonForAnalytics,
                remindLater: remindLater,
                countryCode: countryCode))
    }
}
