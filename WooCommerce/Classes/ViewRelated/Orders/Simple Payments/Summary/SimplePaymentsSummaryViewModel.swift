import Foundation

/// `ViewModel` to drive the content of the `SimplePaymentsSummary` view.
///
final class SimplePaymentsSummaryViewModel: ObservableObject {

    /// Initial amount to charge. Without taxes.
    ///
    let providedAmount: String

    /// Total to charge.
    ///
    let total: String

    init(providedAmount: String) {
        self.providedAmount = providedAmount

        // TODO: Add taxes calculation
        self.total = providedAmount
    }
}
