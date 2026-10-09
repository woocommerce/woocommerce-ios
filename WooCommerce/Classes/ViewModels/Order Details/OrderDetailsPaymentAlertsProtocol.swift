import UIKit
import Yosemite

/// Protocol for `OrderDetailsPaymentAlerts` to enable unit testing.
@MainActor
protocol OrderDetailsPaymentAlertsProtocol {
    func presentViewModel(viewModel: CardPresentPaymentsModalViewModel)

    func preparingReader(onCancel: @escaping @MainActor @Sendable () -> Void)

    func tapOrInsertCard(title: String, amount: String, inputMethods: CardReaderInput, onCancel: @escaping @MainActor @Sendable () -> Void)

    func cardInserted(title: String, amount: String, onCancel: @escaping @MainActor @Sendable () -> Void)

    func displayReaderMessage(message: String)

    func processingPayment(title: String)

    func error(error: Error, tryAgain: @escaping @MainActor @Sendable () -> Void, dismissCompletion: @escaping @MainActor @Sendable () -> Void)

    func nonRetryableError(from: UIViewController?, error: Error, dismissCompletion: @escaping @MainActor @Sendable () -> Void)
}
