import Foundation
import class WordPressShared.EmailFormatValidator
import Yosemite
import WooFoundation
import Combine

final class ReceiptEmailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var state: PrimaryLoadingButtonStyle.State = .idle
    @Published private(set) var dismiss: Bool = false

    private var order: Order
    private let stores: StoresManager
    private let analytics: Analytics
    private let countryCode: CountryCode
    private let cardReaderModel: String?
    var onDismiss: (Order?) -> Void
    var noticePresenter: NoticePresenter
    var emailValidator: (String) -> Bool = EmailFormatValidator.validate

    init(order: Order,
         stores: StoresManager = ServiceLocator.stores,
         noticesPresenter: NoticePresenter = DefaultNoticePresenter(),
         analytics: Analytics = ServiceLocator.analytics,
         countryCode: CountryCode,
         cardReaderModel: String?,
         onDismiss: @escaping (Order?) -> Void = { _ in }) {
        self.order = order
        self.stores = stores
        self.noticePresenter = noticesPresenter
        self.analytics = analytics
        self.countryCode = countryCode
        self.cardReaderModel = cardReaderModel
        self.onDismiss = onDismiss
    }

    var isEmailValid: Bool {
        emailValidator(email)
    }

    func sendReceipt() {
        let email = email
        let action = ReceiptAction.sendReceipt(order: order, email: email) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.state = .idle
                switch result {
                case let .success(order):
                    self.analytics.track(event: .InPersonPayments.receiptEmailSuccess(
                        countryCode: self.countryCode,
                        cardReaderModel: self.cardReaderModel,
                        source: .api)
                    )
                    self.order = order
                    self.state = .success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.dismiss = true
                    }
                case let .failure(error):
                    DDLogError("Sending email receipt failed: \(error.localizedDescription)")
                    self.analytics.track(event: .InPersonPayments.receiptEmailFailed(
                        error: error,
                        countryCode: self.countryCode,
                        cardReaderModel: self.cardReaderModel,
                        source: .api)
                    )
                    self.noticePresenter.enqueue(notice: Notice(title: Localization.errorNotice, feedbackType: .error))
                }
            }
        }

        self.state = .loading
        stores.dispatch(action)
    }

    func onAppear() {
        analytics.track(event: .InPersonPayments.receiptEmailTapped(
            countryCode: countryCode,
            cardReaderModel: cardReaderModel,
            source: .api)
        )
    }

    func onDisappear() {
        if state != .success {
            analytics.track(event: .InPersonPayments.receiptEmailCanceled(
                countryCode: countryCode,
                cardReaderModel: cardReaderModel,
                source: .api)
            )
        }

        self.noticePresenter.presentingViewController = nil
        onDismiss(order)
    }

    func onCancel() {
        self.dismiss = true
    }
}

private enum Localization {
    static let errorNotice = NSLocalizedString(
        "order.receiptEmailView.errorNotice",
        value: "Error sending the email receipt. Please try again.",
        comment: "An error that is shown when sending email receipt fails."
    )

}
