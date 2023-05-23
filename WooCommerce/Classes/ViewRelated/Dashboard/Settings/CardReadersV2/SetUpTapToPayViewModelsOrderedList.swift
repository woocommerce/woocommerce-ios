import Foundation
import Yosemite
import Combine

/// Aggregates an ordered list of viewmodels, conforming to the viewmodel provider protocol. Priority is given to
/// the first viewmodel in the list to return true for shouldShow
///
final class SetUpTapToPayViewModelsOrderedList: PaymentSettingsFlowPrioritizedViewModelsProvider {

    private var viewModelsAndViews = [PaymentSettingsFlowViewModelAndView]()

    var priorityViewModelAndView: PaymentSettingsFlowViewModelAndView? {
        didSet {
            onPriorityChanged?(priorityViewModelAndView)
        }
    }

    var onPriorityChanged: ((PaymentSettingsFlowViewModelAndView?) -> ())?

    private var knownReaderProvider: CardReaderSettingsKnownReaderProvider?

    private let cardReaderConnectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker

    private var cancellables = Set<AnyCancellable>()

    init(siteID: Int64,
         configuration: CardPresentPaymentsConfiguration,
         onboardingUseCase: CardPresentPaymentsOnboardingUseCase) {
        /// Initialize dependencies for viewmodels first, then viewmodels
        ///
        cardReaderConnectionAnalyticsTracker = .init(configuration: configuration,
                                                     siteID: siteID,
                                                     connectionType: .userInitiated)
        onboardingUseCase.statePublisher.share().sink { [weak self] onboardingState in
            guard case .completed(let plugin) = onboardingState else {
                return
            }
            self?.cardReaderConnectionAnalyticsTracker.setGatewayID(gatewayID: plugin.preferred.gatewayID)
        }.store(in: &cancellables)

        /// Instantiate and add each viewmodel related to setting up Tap to Pay on iPhone to the
        /// array. Viewmodels will be evaluated for shouldShow starting at the top
        /// of the array. The first viewmodel to return true for shouldShow is given
        /// priority, so viewmodels related to starting set up should come before viewmodels
        /// that expect set up to be completed, etc.
        ///
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.tapToPayOnIPhoneMilestone2) {
            viewModelsAndViews.append(PaymentSettingsFlowViewModelAndView(
                viewModel: InPersonPaymentsViewModel(useCase: onboardingUseCase,
                                                     didChangeShouldShow: { [weak self] state in
                                                         self?.onDidChangeShouldShow(state)
                                                     }),
                viewPresenter: SetUpTapToPayOnboardingViewController.self))
        }

        viewModelsAndViews.append(contentsOf: [
            PaymentSettingsFlowViewModelAndView(
                viewModel: SetUpTapToPayInformationViewModel(
                    siteID: siteID,
                    configuration: configuration,
                    didChangeShouldShow: { [weak self] state in
                        self?.onDidChangeShouldShow(state)
                    },
                    onboardingStatePublisher: onboardingUseCase.statePublisher,
                    connectionAnalyticsTracker: cardReaderConnectionAnalyticsTracker
                ),
                viewPresenter: SetUpTapToPayInformationViewController.self
            ),

            PaymentSettingsFlowViewModelAndView(
                viewModel: SetUpTapToPayCompleteViewModel(
                    didChangeShouldShow: { [weak self] state in
                        self?.onDidChangeShouldShow(state)
                    },
                    connectionAnalyticsTracker: cardReaderConnectionAnalyticsTracker
                ),
                viewPresenter: SetUpTapToPayCompleteViewController.self
            ),

            PaymentSettingsFlowViewModelAndView(
                viewModel: SetUpTapToPayTryPaymentPromptViewModel(
                    didChangeShouldShow: { [weak self] state in
                        self?.onDidChangeShouldShow(state)
                    },
                    connectionAnalyticsTracker: cardReaderConnectionAnalyticsTracker
                ),
                viewPresenter: SetUpTapToPayTryPaymentPromptViewController.self
            ),
        ])

        /// And then immediately get a priority view if possible
        reevaluatePriorityViewModelAndView()
    }

    private func onDidChangeShouldShow(_ : CardReaderSettingsTriState) {
        reevaluatePriorityViewModelAndView()
    }

    private func reevaluatePriorityViewModelAndView() {
        let newPriorityViewModelAndView = viewModelsAndViews.first(
            where: { $0.viewModel.shouldShow == .isTrue }
        )

        guard newPriorityViewModelAndView != priorityViewModelAndView else {
            return
        }

        priorityViewModelAndView = newPriorityViewModelAndView
    }
}
