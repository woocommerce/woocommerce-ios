import Foundation
import Combine
import Yosemite
import MessageUI
import protocol Storage.StorageManagerType

/// Protocol to abstract the `CollectOrderPaymentUseCase`.
/// Currently only used to facilitate unit tests.
///
protocol CollectOrderPaymentProtocol {
    /// Starts the collect payment flow.
    ///
    ///
    /// - Parameter backButtonTitle: Title for the back button after a payment is sucessfull.
    /// - Parameter onCollect: Closure Invoked after the collect process has finished.
    /// - Parameter onCompleted: Closure Invoked after the flow has been totally completed.
    func collectPayment(backButtonTitle: String, onCollect: @escaping (Result<Void, Error>) -> (), onCompleted: @escaping () -> ())
}

/// Use case to collect payments from an order.
/// Orchestrates reader connection, payment, UI alerts, receipt handling and analytics.
///
final class CollectOrderPaymentUseCase: NSObject, CollectOrderPaymentProtocol {
    /// Store's ID.
    ///
    private let siteID: Int64

    /// Order to collect.
    ///
    private let order: Order

    /// Formatted amount to collect.
    ///
    private let formattedAmount: String

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
                                       knownReaderProvider: CardReaderSettingsKnownReaderStorage(),
                                       alertsProvider: CardReaderSettingsAlerts())
    }()

    init(siteID: Int64,
         order: Order,
         formattedAmount: String,
         paymentGatewayAccount: PaymentGatewayAccount,
         rootViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.order = order
        self.formattedAmount = formattedAmount
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
    /// - Parameter backButtonTitle: Title for the back button after a payment is sucessfull.
    /// - Parameter onCollect: Closure Invoked after the collect process has finished.
    /// - Parameter onCompleted: Closure Invoked after the flow has been totally completed, Currently after merchant has handled the receipt.
    func collectPayment(backButtonTitle: String, onCollect: @escaping (Result<Void, Error>) -> (), onCompleted: @escaping () -> ()) {
        configureBackend()
        connectReader { [weak self] in
            self?.attemptPayment(onCompletion: { [weak self] result in
                // Inform about the collect payment state
                onCollect(result.map { _ in () }) // Transforms Result<CardPresentReceiptParameters, Error> to Result<Void, Error>

                // Handle payment receipt
                guard let receiptParameters = try? result.get() else {
                    return
                }
                self?.presentReceiptAlert(receiptParameters: receiptParameters, backButtonTitle: backButtonTitle, onCompleted: onCompleted)
            })
        }
    }
}

// MARK: Private functions
private extension CollectOrderPaymentUseCase {
    /// Configure the CardPresentPaymentStore to use the appropriate backend
    ///
    func configureBackend() {
        let setAccount = CardPresentPaymentAction.use(paymentGatewayAccount: paymentGatewayAccount)
        stores.dispatch(setAccount)
    }

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
                    // Dismiss the current connection alert before notifying the completion.
                    // If no presented controller is found(because the reader was already connected), just notify the completion.
                    if let connectionController = self?.rootViewController.presentedViewController {
                        connectionController.dismiss(animated: true) {
                            onCompletion()
                        }
                    } else {
                        onCompletion()
                    }

                    // Nil the subscription since we are done with the connection.
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
        // Track tapped event
        analytics.track(event: WooAnalyticsEvent.InPersonPayments.collectPaymentTapped(forGatewayID: paymentGatewayAccount.gatewayID))

        // Show reader ready alert
        alerts.readerIsReady(title: Localization.collectPaymentTitle(username: order.billingAddress?.firstName), amount: formattedAmount)

        // Start collect payment process
        paymentOrchestrator.collectPayment(
            for: order,
               paymentGatewayAccount: paymentGatewayAccount,
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
        analytics.track(event: WooAnalyticsEvent.InPersonPayments.collectPaymentSuccess(forGatewayID: paymentGatewayAccount.gatewayID))

        // Success Callback
        onCompletion(.success(receipt))
    }

    /// Log the failure reason, cancel the current payment and retry it if possible.
    ///
    func handlePaymentFailureAndRetryPayment(_ error: Error, onCompletion: @escaping (Result<CardPresentReceiptParameters, Error>) -> ()) {
        // Record error
        analytics.track(event: WooAnalyticsEvent.InPersonPayments.collectPaymentFailed(forGatewayID: paymentGatewayAccount.gatewayID, error: error))
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
        paymentOrchestrator.cancelPayment { [weak self, analytics] _ in
            guard let self = self else { return }
            analytics.track(event: WooAnalyticsEvent.InPersonPayments.collectPaymentCanceled(forGatewayID: self.paymentGatewayAccount.gatewayID))
        }
    }

    /// Allow merchants to print or email the payment receipt.
    ///
    func presentReceiptAlert(receiptParameters: CardPresentReceiptParameters, backButtonTitle: String, onCompleted: @escaping () -> ()) {
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
        }, noReceiptTitle: backButtonTitle,
           noReceiptAction: {
            // Inform about flow completion.
            onCompleted()
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
        private static let emailSubjectWithStoreName = NSLocalizedString("Your receipt from %1$@",
                                                                 comment: "Subject of email sent with a card present payment receipt")
        private static let emailSubjectWithoutStoreName = NSLocalizedString("Your receipt",
                                                                    comment: "Subject of email sent with a card present payment receipt")
        static func emailSubject(storeName: String?) -> String {
            guard let storeName = storeName, storeName.isNotEmpty else {
                return emailSubjectWithoutStoreName
            }
            return .localizedStringWithFormat(emailSubjectWithStoreName, storeName)
        }

        private static let collectPaymentWithoutName = NSLocalizedString("Collect payment",
                                                                 comment: "Alert title when starting the collect payment flow without a user name.")
        private static let collectPaymentWithName = NSLocalizedString("Collect payment from %1$@",
                                                                 comment: "Alert title when starting the collect payment flow with a user name.")
        static func collectPaymentTitle(username: String?) -> String {
            guard let username = username, username.isNotEmpty else {
                return collectPaymentWithoutName
            }
            return .localizedStringWithFormat(collectPaymentWithName, username)
        }
    }
}
