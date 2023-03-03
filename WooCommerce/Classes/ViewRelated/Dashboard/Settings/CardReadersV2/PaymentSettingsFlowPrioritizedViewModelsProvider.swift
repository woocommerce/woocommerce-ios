import Foundation

/// Defines a protocol for conforming classes to reveal which of several peer viewmodels and views
/// should have the priority at a given moment.
///
protocol PaymentSettingsFlowPrioritizedViewModelsProvider {

    /// Allows the caller (i.e. a Presenting View Controller) to register a callback to be informed when the
    /// priorty viewmodel changes so that it can change what view controller it presents. It is possible
    /// that NO viewmodel has the priority, hence the optionality.
    ///
    var onPriorityChanged: ((PaymentSettingsFlowViewModelAndView?) -> ())? { get set }

    /// Returns which viewmodel (and view), if any, should have the priority
    ///
    var priorityViewModelAndView: PaymentSettingsFlowViewModelAndView? { get }
}
