import Foundation
import Combine
import Yosemite
import MessageUI
import protocol Storage.StorageManagerType

/// Use case to collect payments from an order.
/// Orchestrates reader connection, payment, UI alerts, receipt handling and analytics.
///
final class CollectOrderPaymentUseCase: NSObject {

    /// Store's ID.
    ///
    private let siteID: Int64

    /// Order to collect.
    ///
    private let order: Order

    /// Payment Gateway Account to use.
    ///
    private let paymentGatewayAccount: PaymentGatewayAccount

    /// Stores manager.
    ///
    private let stores: StoresManager

    /// Analytics manager,
    ///
    private let analytics: Analytics

    /// View Controller used to present alerts.
    ///
    private var rootViewController: UIViewController

    /// Stores the card reader listener subscription while trying to connect to one.
    ///
    private var readerSubscription: AnyCancellable?

    /// Closure to inform when the full flow has been completed, after receipt management.
    /// Needed to be saved as an instance variable because it needs to be referenced from the `MailComposer` delegate.
    ///
    private var onCompleted: (() -> ())?

    /// Alert manager to inform merchants about reader & card actions.
    ///
    private lazy var alerts = OrderDetailsPaymentAlerts(presentingController: rootViewController)

    /// IPP payments collector.
    ///
    private lazy var paymentOrchestrator = PaymentCaptureOrchestrator()

    /// Controller to connect a card reader.
    ///
    private lazy var connectionController = {
        CardReaderConnectionController(forSiteID: siteID,
                                       knownReaderProvider: CardReaderSettingsKnownReaderStorage(), alertsProvider: CardReaderSettingsAlerts())
    }()

    init(siteID: Int64,
         order: Order,
         paymentGatewayAccount: PaymentGatewayAccount,
         rootViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.order = order
        self.paymentGatewayAccount = paymentGatewayAccount
        self.rootViewController = rootViewController
        self.stores = stores
        self.analytics = analytics
    }

    /// Starts the collect payment flow.
    /// 1. Connects to a reader
    /// 2. Collect payment from order
    /// 3. If successful: prints or emails receipt
    /// 4. If failure: Allows retry
    ///
    ///
    /// - Parameter onCollect: Closure Invoked after the collect process has finished.
    /// - Parameter onCompleted: Closure Invoked after the flow has been totally completed, Currently after merchant has handled the receipt.
    // TODO: Remember to check why the amount is provided in order details view model
    func collectPayment(onCollect: @escaping (Result<Void, Error>) -> (), onCompleted: @escaping () -> ()) {
        connectReader { [weak self] in
            self?.attemptPayment(onCompletion: { [weak self] result in
                // Inform about the collect payment state
                onCollect(result.map { _ in () }) // Transforms Result<CardPresentReceiptParameters, Error> to Result<Void, Error>

                // Handle payment receipt
                guard let receiptParameters = try? result.get() else {
                    return
                }
                self?.presentReceiptAlert(receiptParameters: receiptParameters, onCompleted: onCompleted)
            })
        }
    }
}

// MARK: Private functions
private extension CollectOrderPaymentUseCase {

    /// Attempts to connect to a reader.
    /// Finishes immediately if a reader is already connected.
    ///
    func connectReader(onCompletion: @escaping () -> ()) {
        // `checkCardReaderConnected` action will return a publisher that:
        // - Sends one value if there is no reader connected.
        // - Completes when a reader is connected.
        let readerConnected = CardPresentPaymentAction.checkCardReaderConnected { connectPublisher in
            self.readerSubscription = connectPublisher
                .sink(receiveCompletion: { [weak self] _ in
                    // Reader connected
                    onCompletion()

                    // Nil the subscription since we are don with the connection.
                    self?.readerSubscription = nil

                }, receiveValue: { [weak self] _ in
                    guard let self = self else { return }

                    // Attempt reader connection
                    self.connectionController.searchAndConnect(from: self.rootViewController) { _ in }
                })
        }
        stores.dispatch(readerConnected)
    }

    /// Attempts to collect payment for an order.
    ///
    func attemptPayment(onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> ()) {

        // TODO: paymentAlerts.readerIsReady(title: viewModel.collectPaymentFrom, amount: value)
        // TODO: ServiceLocator.analytics.track(.collectPaymentTapped)

        paymentOrchestrator.collectPayment(
            for: order,
            statementDescriptor: paymentGatewayAccount.statementDescriptor,
            onWaitingForInput: { [weak self] in
                // Request card input
                self?.alerts.tapOrInsertCard(onCancel: {
                    self?.cancelPayment()
                })

            }, onProcessingMessage: { [weak self] in
                // Waiting message
                self?.alerts.processingPayment()

            }, onDisplayMessage: { [weak self] message in
                // Reader messages. EG: Remove Card
                self?.alerts.displayReaderMessage(message: message)

            }, onCompletion: { [weak self] result in
                switch result {
                case .success(let receiptParameters):
                    self?.handleSuccessfulPayment(receipt: receiptParameters, onCompletion: onCompletion)
                case .failure(let error):
                    self?.handlePaymentFailureAndRetryPayment(error, onCompletion: onCompletion)
                }
            }
        )
    }

    /// Tracks the successful payments
    ///
    func handleSuccessfulPayment(receipt: CardPresentReceiptParameters, onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> ()) {
        // Record success
        analytics.track(.collectPaymentSuccess)

        // Success Callback
        onCompletion(.success(receipt))
    }

    /// Log the failure reason, cancel the current payment and retry it if possible.
    ///
    func handlePaymentFailureAndRetryPayment(_ error: Error, onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> ()) {
        // Record error
        analytics.track(.collectPaymentFailed, withError: error)
        DDLogError("Failed to collect payment: \(error.localizedDescription)")

        // Inform about the error
        alerts.error(error: error) { [weak self] in

            // Cancel current payment
            self?.paymentOrchestrator.cancelPayment { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    // Retry payment
                    self.attemptPayment(onCompletion: onCompletion)

                case .failure(let cancelError):
                    // Inform that payment can't be retried.
                    self.alerts.nonRetryableError(from: self.rootViewController, error: cancelError)
                    onCompletion(.failure(error))
                }
            }
        }
    }

    /// Cancels payment and record analytics.
    ///
    func cancelPayment() {
        paymentOrchestrator.cancelPayment { [analytics] _ in
            analytics.track(.collectPaymentCanceled)
        }
    }

    /// Allow merchants to print or email the payment receipt.
    ///
    func presentReceiptAlert(receiptParameters: CardPresentReceiptParameters, onCompleted: @escaping () -> ()) {
        // Present receipt alert
        alerts.success(printReceipt: { [order] in
            // Inform about flow completion.
            onCompleted()

            // Delegate print action
            ReceiptActionCoordinator.printReceipt(for: order, params: receiptParameters)

        }, emailReceipt: { [order, analytics, paymentOrchestrator] in
            // Record button tapped
            analytics.track(.receiptEmailTapped)

            // Request & present email
            paymentOrchestrator.emailReceipt(for: order, params: receiptParameters) { [weak self] emailContent in
                self?.onCompleted = onCompleted // Saved to be able to reference from the `MailComposer` delegate.
                self?.presentEmailForm(content: emailContent)
            }
        })
    }

    /// Presents the native email client with the provided content.
    ///
    func presentEmailForm(content: String) {
        guard MFMailComposeViewController.canSendMail() else {
            return DDLogError("⛔️ Failed to submit email receipt for order: \(order.orderID). Email is not configured.")
        }

        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self

        mail.setSubject(Localization.emailSubject(storeName: stores.sessionManager.defaultSite?.name))
        mail.setMessageBody(content, isHTML: true)

        if let customerEmail = order.billingAddress?.email {
            mail.setToRecipients([customerEmail])
        }

        rootViewController.present(mail, animated: true)
    }
}

// MARK: MailComposer Delegate
extension CollectOrderPaymentUseCase: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            analytics.track(.receiptEmailCanceled)
        case .sent, .saved:
            analytics.track(.receiptEmailSuccess)
        case .failed:
            analytics.track(.receiptEmailFailed, withError: error ?? UnknownEmailError())
        @unknown default:
            assertionFailure("MFMailComposeViewController finished with an unknown result type")
        }

        // Dismiss email controller & inform flow completion.
        controller.dismiss(animated: true) { [weak self] in
            self?.onCompleted?()
            self?.onCompleted = nil
        }
    }
}

// MARK: Definitions
private extension CollectOrderPaymentUseCase {
    /// Mailing a receipt failed but the SDK didn't return a more specific error
    ///
    struct UnknownEmailError: Error {}

    enum Localization {
        static let emailSubjectWithStoreName = NSLocalizedString("Your receipt from %1$@",
                                                                 comment: "Subject of email sent with a card present payment receipt")
        static let emailSubjectWithoutStoreName = NSLocalizedString("Your receipt",
                                                                    comment: "Subject of email sent with a card present payment receipt")
        static func emailSubject(storeName: String?) -> String {
            guard let storeName = storeName else {
                return emailSubjectWithoutStoreName
            }
            return .localizedStringWithFormat(emailSubjectWithStoreName, storeName)
        }
    }
}
