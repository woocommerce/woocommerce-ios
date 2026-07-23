import UIKit
import SwiftUI
import struct Yosemite.Order
import WooFoundation

/// Coordinates the navigation from a given view controller to present a mail composer for a card-present payment receipt.
final class CardPresentPaymentReceiptEmailCoordinator {
    private let analytics: Analytics
    private let countryCode: CountryCode
    private let cardReaderModel: String?

    init(analytics: Analytics = ServiceLocator.analytics, countryCode: CountryCode, cardReaderModel: String?) {
        self.analytics = analytics
        self.countryCode = countryCode
        self.cardReaderModel = cardReaderModel
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

private extension CardPresentPaymentReceiptEmailCoordinator {
    enum Localization {
        private static let collectPaymentWithoutName = NSLocalizedString("Collect payment",
                                                                         comment: "Alert title when starting the collect payment flow without a user name.")
        private static let collectPaymentWithName = NSLocalizedString("Collect payment from %1$@",
                                                                      comment: "Alert title when starting the collect payment flow with a user name.")
        static func collectPaymentTitle(username: String?) -> String {
            guard let username, username.isNotEmpty else {
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
