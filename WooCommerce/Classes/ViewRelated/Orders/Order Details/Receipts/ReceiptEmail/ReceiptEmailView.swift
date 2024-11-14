import SwiftUI
import Yosemite

struct ReceiptEmailView: View {
    @ObservedObject var viewModel: ReceiptEmailViewModel

    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 0) {
                    Divider()
                    TitleAndTextFieldRow(title: Localization.emailField,
                                         placeholder: Localization.emailHint,
                                         text: $viewModel.email,
                                         symbol: nil,
                                         fieldAlignment: .leading,
                                         keyboardType: .emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused()
                    .onSubmit(viewModel.sendReceipt)
                    Divider()
                }
                .background(Color(.systemBackground).ignoresSafeArea(.container, edges: .horizontal))
                Spacer()

                Button(Localization.emailButton) {
                    viewModel.sendReceipt()
                }
                .disabled(!viewModel.isEmailValid)
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLoading))
                .padding()
            }
            .padding(.top)
            .background(Color(uiColor: .listBackground))
            .wooNavigationBarStyle()
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel, action: {
                        viewModel.onDismiss(false)
                    })
                }
            }
        }
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "order.receiptEmailView.title",
        value: "Email Receipt to Customer",
        comment: "Title for the screen to update customer email address and send receipt"
    )

    static let emailField = NSLocalizedString(
        "order.receiptEmailView.emailFieldTitle",
        value: "Email",
        comment: "Email text field title"
    )

    static let emailHint = NSLocalizedString(
        "order.receiptEmailView.emailFieldHint",
        value: "Enter Email",
        comment: "Email field placeholder"
    )

    static let emailButton = NSLocalizedString(
        "order.receiptEmailView.emailReceipt",
        value: "Email Receipt",
        comment: "Title for the button to send the receipt to the customer"
    )

    static let cancel = NSLocalizedString(
        "order.receiptEmailView.cancel",
        value: "Cancel",
        comment: "Text for the cancel button to dismiss Send Receipt to Customer screen"
    )

    static let invalidEmail = NSLocalizedString(
        "order.receiptEmailView.invalidEmailError",
        value: "Please enter a valid email address.",
        comment: "Notice text when the merchant enters an invalid email"
    )
}

final class ReceiptEmailViewHostingController: UIHostingController<ReceiptEmailView>, UIAdaptivePresentationControllerDelegate {
    private var onDismiss: ((Bool) -> Void)

    init(order: Order,
         stores: StoresManager = ServiceLocator.stores,
         systemNoticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         onDismiss: @escaping (Bool) -> Void) {

        self.onDismiss = onDismiss
        let viewModel = ReceiptEmailViewModel(order: order, stores: stores, onDismiss: onDismiss)
        super.init(rootView: ReceiptEmailView(viewModel: viewModel))

        viewModel.onDismiss = { [weak self] success in
            self?.dismiss(animated: true, completion: nil)
            onDismiss(success)
        }

        presentationController?.delegate = self
        viewModel.noticePresenter.presentingViewController = self
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss(false)
    }
}
