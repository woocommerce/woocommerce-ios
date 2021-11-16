import Foundation

/// `ViewModel` to drive the content of the `SimplePaymentsSummary` view.
///
final class SimplePaymentsSummaryViewModel: ObservableObject {

    /// Initial amount to charge. Without taxes.
    ///
    let providedAmount: String

    init(providedAmount: String) {
        self.providedAmount = providedAmount
    }
}
