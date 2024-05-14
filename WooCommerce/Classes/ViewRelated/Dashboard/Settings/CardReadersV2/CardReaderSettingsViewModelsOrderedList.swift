import Foundation
import protocol Yosemite.CardReaderSettingsKnownReaderProvider
import struct Yosemite.CardPresentPaymentsConfiguration

/// Aggregates an ordered list of viewmodels, conforming to the viewmodel provider protocol. Priority is given to
/// the first viewmodel in the list to return true for shouldShow
///
final class CardReaderSettingsViewModelsOrderedList: PaymentSettingsFlowPrioritizedViewModelsProvider {

    private var viewModelsAndViews = [PaymentSettingsFlowViewModelAndView]()

    var priorityViewModelAndView: PaymentSettingsFlowViewModelAndView? {
        didSet {
            onPriorityChanged?(priorityViewModelAndView)
        }
    }

    var onPriorityChanged: ((PaymentSettingsFlowViewModelAndView?) -> ())?

    private let knownReaderProvider: CardReaderSettingsKnownReaderProvider?

    private let cardReaderConnectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker

    init(configuration: CardPresentPaymentsConfiguration, siteID: Int64) {
        /// Initialize dependencies for viewmodels first, then viewmodels
        ///
        knownReaderProvider = CardReaderSettingsKnownReaderStorage()

        cardReaderConnectionAnalyticsTracker = CardReaderConnectionAnalyticsTracker(configuration: configuration,
                                                                                    siteID: siteID,
                                                                                    connectionType: .userInitiated)

        /// Instantiate and add each viewmodel related to card reader settings to the
        /// array. Viewmodels will be evaluated for shouldShow starting at the top
        /// of the array. The first viewmodel to return true for shouldShow is given
        /// priority, so viewmodels related to no-known-readers should come before viewmodels
        /// that expect a connected reader, etc.
        ///
        viewModelsAndViews.append(
            PaymentSettingsFlowViewModelAndView(
                viewModel: CardReaderSettingsSearchingViewModel(
                    didChangeShouldShow: { [weak self] state in
                        self?.onDidChangeShouldShow(state)
                    },
                    knownReaderProvider: knownReaderProvider,
                    configuration: configuration,
                    cardReaderConnectionAnalyticsTracker: cardReaderConnectionAnalyticsTracker
                ),
                viewPresenter: CardReaderSettingsSearchingViewController.self
            )
        )

        viewModelsAndViews.append(
            PaymentSettingsFlowViewModelAndView(
                viewModel: BluetoothCardReaderSettingsConnectedViewModel(
                    didChangeShouldShow: { [weak self] state in
                        self?.onDidChangeShouldShow(state)
                    },
                    knownReaderProvider: knownReaderProvider,
                    configuration: configuration,
                    analyticsTracker: cardReaderConnectionAnalyticsTracker
                ),
                viewPresenter: CardReaderSettingsConnectedViewController.self
            )
        )

        /// And then immediately get a priority view if possible
        reevaluatePriorityViewModelAndView()
    }

    private func onDidChangeShouldShow(_: CardReaderSettingsTriState) {
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
