import Foundation
import class WordPressShared.EmailFormatValidator
import Yosemite

final class ReceiptEmailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var state: PrimaryLoadingButtonStyle.State = .idle

    private let order: Order
    private let stores: StoresManager
    var noticePresenter: NoticePresenter
    var emailValidator: (String) -> Bool = EmailFormatValidator.validate
    var onDismiss: (Order?) -> Void

    init(order: Order,
         stores: StoresManager,
         noticesPresenter: NoticePresenter = DefaultNoticePresenter(),
         onDismiss: @escaping (Order?) -> Void = { _ in }) {
        self.order = order
        self.stores = stores
        self.noticePresenter = noticesPresenter
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
                    self.state = .success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.onDismiss(order)
                    }
                case let .failure(error):
                    DDLogError("Sending email receipt failed: \(error.localizedDescription)")
                    self.noticePresenter.enqueue(notice: Notice(title: Localization.errorNotice, feedbackType: .error))
                 }
            }
        }

        self.state = .loading
        stores.dispatch(action)
    }
}

private enum Localization {
    static let errorNotice = NSLocalizedString(
        "order.receiptEmailView.errorNotice",
        value: "Error sending the email receipt. Please try again.",
        comment: "An error that is shown when sending email receipt fails."
    )

}
