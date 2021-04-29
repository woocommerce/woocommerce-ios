import Foundation

protocol CardReaderSettingsPresentedViewModel {
    func shouldShow() -> Bool
}

struct CardReaderSettingsViewModelAndView {
    var viewModel: CardReaderSettingsPresentedViewModel
    var viewIdentifier: String
}
