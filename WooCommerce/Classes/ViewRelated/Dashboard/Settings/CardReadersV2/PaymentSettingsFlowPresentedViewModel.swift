import Foundation
import Combine

/// Defines a protocol that all Payment Settings Flow View Models should conform to
///
protocol PaymentSettingsFlowPresentedViewModel {
    /// Whether this view model and the view it connects to should be shown
    ///
    var shouldShow: CardReaderSettingsTriState { get }

    /// Called whenever this view model has changed its `shouldShow` value
    ///
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)? { get set }

    /// Allows the view controller to register a callback to be informed when the viewmodel changes, e.g in
    /// the view controller's `configure(viewModel: CardReaderSettingsPresentedViewModel)` method
    /// Care should be taken to avoid reference cycles by un-setting the callback, e.g. in the view controller's `viewWillDisappear`
    ///
    var didUpdate: (() -> Void)? { get set }
}

struct PaymentSettingsFlowViewModelAndView: Equatable {
    static func == (lhs: PaymentSettingsFlowViewModelAndView, rhs: PaymentSettingsFlowViewModelAndView) -> Bool {
        // It is sufficient to test on just the view identifier. No need to compare the viewmodels.
        lhs.viewPresenter == rhs.viewPresenter
    }

    var viewModel: PaymentSettingsFlowPresentedViewModel
    var viewPresenter: PaymentSettingsFlowViewModelPresenter.Type
}

enum CardReaderSettingsTriState {
    case isUnknown
    case isFalse
    case isTrue
}
