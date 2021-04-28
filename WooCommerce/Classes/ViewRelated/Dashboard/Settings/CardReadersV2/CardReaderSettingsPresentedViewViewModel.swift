import Foundation

protocol CardReaderSettingsPresentedViewModel {
    func shouldShow() -> Bool
}

/// A tuple containing a reference to the view model for a presented view and the related view controller's class name.
typealias CardReaderSettingsViewModelAndView = (CardReaderSettingsPresentedViewModel, String)
