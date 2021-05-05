import Foundation
import Combine

protocol CardReaderSettingsPresentedViewModel {
    var shouldShow: CardReaderSettingsTriState { get }
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)? { get set }
}

struct CardReaderSettingsViewModelAndView: Equatable {
    static func == (lhs: CardReaderSettingsViewModelAndView, rhs: CardReaderSettingsViewModelAndView) -> Bool {
        // It is sufficient to test on just the view identifier. No need to compare the viewmodels.
        lhs.viewIdentifier == rhs.viewIdentifier
    }

    var viewModel: CardReaderSettingsPresentedViewModel
    var viewIdentifier: String
}

enum CardReaderSettingsTriState {
    case isUnknown
    case isFalse
    case isTrue
}
