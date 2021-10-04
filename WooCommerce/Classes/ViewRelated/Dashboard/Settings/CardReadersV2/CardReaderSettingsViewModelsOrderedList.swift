import Foundation

/// Aggregates an ordered list of viewmodels, conforming to the viewmodel provider protocol. Priority is given to
/// the first viewmodel in the list to return true for shouldShow
///
final class CardReaderSettingsViewModelsOrderedList: CardReaderSettingsPrioritizedViewModelsProvider {

    private var viewModelsAndViews = [CardReaderSettingsViewModelAndView]()

    var priorityViewModelAndView: CardReaderSettingsViewModelAndView? {
        didSet {
            onPriorityChanged?(priorityViewModelAndView)
        }
    }

    var onPriorityChanged: ((CardReaderSettingsViewModelAndView?) -> ())?

    private var knownReaderProvider: CardReaderSettingsKnownReaderProvider?

    init() {
        /// Initialize dependencies for viewmodels first, then viewmodels
        ///
        knownReaderProvider = CardReaderSettingsKnownReaderStorage()

        /// Instantiate and add each viewmodel related to card reader settings to the
        /// array. Viewmodels will be evaluated for shouldShow starting at the top
        /// of the array. The first viewmodel to return true for shouldShow is given
        /// priority, so viewmodels related to no-known-readers should come before viewmodels
        /// that expect a connected reader, etc.
        ///
        viewModelsAndViews.append(
            CardReaderSettingsViewModelAndView(
                viewModel: CardReaderSettingsSearchingViewModel(
                    didChangeShouldShow: { [weak self] state in
                        self?.onDidChangeShouldShow(state)
                    },
                    knownReaderProvider: knownReaderProvider
                ),
                viewIdentifier: "CardReaderSettingsSearchingViewController"
            )
        )

        viewModelsAndViews.append(
            CardReaderSettingsViewModelAndView(
                viewModel: CardReaderSettingsConnectedViewModel(
                    didChangeShouldShow: { [weak self] state in
                        self?.onDidChangeShouldShow(state)
                    },
                    knownReaderProvider: knownReaderProvider
                ),
                viewIdentifier: "CardReaderSettingsConnectedViewController"
            )
        )

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
