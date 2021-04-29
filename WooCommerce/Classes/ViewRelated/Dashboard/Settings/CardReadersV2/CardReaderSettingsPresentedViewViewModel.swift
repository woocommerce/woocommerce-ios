import Foundation
import Combine

protocol CardReaderSettingsPresentedViewModel {
    var shouldShow: Bool { get }
    var didChangeShouldShow: ((Bool) -> Void)? { get set }
}

struct CardReaderSettingsViewModelAndView {
    var viewModel: CardReaderSettingsPresentedViewModel
    var viewIdentifier: String
}
