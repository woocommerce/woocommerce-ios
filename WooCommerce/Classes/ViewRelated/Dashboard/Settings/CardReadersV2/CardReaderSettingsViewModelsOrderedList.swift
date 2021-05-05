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

    init() {
        /// Instantiate and add each viewmodel related to card reader settings to the
        /// array. Viewmodels will be evaluated for shouldShow starting at the top
        /// of the array. The first viewmodel to return true for shouldShow is given
        /// priority, so viewmodels related to no-known-readers should come before viewmodels
        /// that expect a connected reader, etc.
        ///
        viewModelsAndViews.append(
            CardReaderSettingsViewModelAndView(
                viewModel: CardReaderSettingsUnknownViewModel(
                    didChangeShouldShow: onDidChangeShouldShow
                ),
                viewIdentifier: "CardReaderSettingsUnknownViewController"
            )
        )
        viewModelsAndViews.append(
            CardReaderSettingsViewModelAndView(
                viewModel: CardReaderSettingsConnectedViewModel(
                    didChangeShouldShow: onDidChangeShouldShow
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

        if newPriorityViewModelAndView != priorityViewModelAndView {
            priorityViewModelAndView = newPriorityViewModelAndView
        }
    }
}
