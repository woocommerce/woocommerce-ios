import MessageUI
import UIKit
import SwiftUI
import struct Yosemite.Order
import WooFoundation

/// Coordinates the navigation from a given view controller to present a mail composer for a card-present payment receipt.
final class CardPresentPaymentReceiptEmailCoordinator: NSObject {
    private let analytics: Analytics
    private let countryCode: CountryCode
    private let cardReaderModel: String?

    private var completion: (() -> Void)?

    /// Contains necessary data to email a receipt.
    struct EmailFormData: Equatable {
        /// HTML content of the receipt.
        let content: String

        /// Order of the receipt.
        let order: Order

        /// Name of the store that issues the receipt.
        let storeName: String?
    }

    init(analytics: Analytics = ServiceLocator.analytics, countryCode: CountryCode, cardReaderModel: String?) {
        self.analytics = analytics
        self.countryCode = countryCode
        self.cardReaderModel = cardReaderModel
    }

    /// Presents the native email client with the provided receipt content in HTML.
    ///
    /// - Parameters:
    ///   - data: necessary data for email a receipt.
    ///   - viewController: view controller to present the email form.
    ///   - cardReaderModel: if a card reader is connected, the reader model is used for analytics.
    ///   - completion: called when the user completes emailing the receipt.
    func presentEmailForm(data: EmailFormData,
                          from viewController: ViewControllerPresenting,
                          completion: @escaping () -> Void) {
        guard MFMailComposeViewController.canSendMail() else {
            DDLogError("⛔️ Failed to submit email receipt for order: \(data.order.orderID). Email is not configured.")
            return completion()
        }

        self.completion = completion

        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self

        mail.setSubject(Localization.emailSubject(storeName: data.storeName))
        mail.setMessageBody(data.content, isHTML: true)

        if let customerEmail = data.order.billingAddress?.email {
            mail.setToRecipients([customerEmail])
        }

        viewController.present(mail, animated: true)
    }

    /// Presents the email form after a payment is completed.
    /// - Parameters:
    ///  - viewController: view controller to present the email form.
    ///  - order: order to be updated.
    ///  - onCompleted: called when the user completes emailing the receipt.
    func presentSendReceiptAfterPayment(from viewController: ViewControllerPresenting,
                                        order: Order,
                                        onCompleted: @escaping ((Order?) -> Void)) {
        analytics.track(event: .InPersonPayments.receiptEmailTapped(
            countryCode: countryCode,
            cardReaderModel: cardReaderModel,
            source: .api)
        )

        let noticePresenter = DefaultNoticePresenter()

        let receiptEmailViewModel = ReceiptEmailViewModel(order: order) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let order):
                analytics.track(event: .InPersonPayments.receiptEmailSuccess(
                    countryCode: countryCode,
                    cardReaderModel: cardReaderModel,
                    source: .api)
                )
                onCompleted(order)
            case .failure(let error):
                analytics.track(event: .InPersonPayments.receiptEmailFailed(
                    error: error,
                    countryCode: countryCode,
                    cardReaderModel: cardReaderModel,
                    source: .api)
                )
                noticePresenter.enqueue(notice: Notice(title: Localization.errorNotice, feedbackType: .error))
            case .canceled:
                analytics.track(event: .InPersonPayments.receiptEmailCanceled(
                    countryCode: countryCode,
                    cardReaderModel: cardReaderModel,
                    source: .api)
                )
                onCompleted(nil)
            }
        }

        let receiptEmailViewController = UIHostingController(rootView: ReceiptEmailView(viewModel: receiptEmailViewModel))
        noticePresenter.presentingViewController = receiptEmailViewController
        viewController.present(receiptEmailViewController, animated: true)
    }
}

// MARK: MailComposer Delegate
extension CardPresentPaymentReceiptEmailCoordinator: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            analytics.track(event: .InPersonPayments.receiptEmailCanceled(countryCode: countryCode,
                                                                          cardReaderModel: cardReaderModel,
                                                                          source: .local))
        case .sent, .saved:
            analytics.track(event: .InPersonPayments.receiptEmailSuccess(countryCode: countryCode,
                                                                         cardReaderModel: cardReaderModel,
                                                                         source: .local))
        case .failed:
            analytics.track(event: .InPersonPayments
                .receiptEmailFailed(error: error ?? UnknownEmailError(),
                                    countryCode: countryCode,
                                    cardReaderModel: cardReaderModel,
                                    source: .local))
        @unknown default:
            assertionFailure("MFMailComposeViewController finished with an unknown result type")
        }

        // Dismiss email controller & inform flow completion.
        controller.dismiss(animated: true) { [weak self] in
            self?.completion?()
            self?.completion = nil
        }
    }
}

private extension CardPresentPaymentReceiptEmailCoordinator {
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

        static let errorNotice = NSLocalizedString(
            "order.receiptEmailView.errorNotice",
            value: "Error sending the email receipt. Please try again.",
            comment: "An error that is shown when sending email receipt fails."
        )
    }
}
