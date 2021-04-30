import Foundation
import Combine

protocol CardReaderSettingsPresentedViewModel {
    var shouldShow: CardReaderSettingsTriState { get }
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)? { get set }
}

struct CardReaderSettingsViewModelAndView {
    var viewModel: CardReaderSettingsPresentedViewModel
    var viewIdentifier: String
}

enum CardReaderSettingsTriState {
    case isUnknown
    case isFalse
    case isTrue
}
