import SwiftUI

struct BlazePaymentMethodsView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0
    @StateObject private var viewModel: BlazePaymentMethodsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddPaymentWebView: Bool = false
    @State private var isShowingLoadPaymentMethodsErrorAlert: Bool = false

    init(viewModel: BlazePaymentMethodsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                secureHeader
                    .renderedIf(!viewModel.isLoadingPaymentMethods)

                ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    .renderedIf(viewModel.isLoadingPaymentMethods)

                // Empty state when there are no payments methods
                noPaymentsView
                    .renderedIf(viewModel.paymentMethods.isEmpty && !viewModel.isLoadingPaymentMethods)

                listView
                    .renderedIf(viewModel.paymentMethods.isNotEmpty)
            }
            .safeAreaInset(edge: .bottom) {
                // Add new method button
                Group {
                    let buttonText = viewModel.paymentMethods.isEmpty ? Localization.addCreditCardButton : Localization.addAnotherCreditCardButton
                    Button(action: {
                        showingAddPaymentWebView = true
                    }) {
                        Text(buttonText)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(Layout.ctaPadding)
                .background(Color(.systemBackground))
                .renderedIf(!viewModel.isLoadingPaymentMethods)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        dismiss()
                    }
                }
            }
            .navigationTitle(Localization.navigationBarTitle)
            .wooNavigationBarStyle()
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAddPaymentWebView, content: {
            if let viewModel = viewModel.addPaymentWebViewModel {
                BlazeAddPaymentMethodWebView(viewModel: viewModel)
            }
        })
        .alert(Localization.LoadPaymentMethodsErrorAlert.paymentMethods, isPresented: $viewModel.showLoadPaymentsErrorAlert) {
            Button(Localization.LoadPaymentMethodsErrorAlert.cancel, role: .cancel) { }

            Button(Localization.LoadPaymentMethodsErrorAlert.retry) {
                Task {
                    await viewModel.reloadPaymentMethods()
                }
            }
        }
        .task {
            await viewModel.reloadPaymentMethods()
        }
    }

    @ViewBuilder
    private var secureHeader: some View {
        HStack(spacing: Layout.SecureHeader.hSpacing) {
            Image(systemName: "checkmark.shield")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: scale * Layout.SecureHeader.iconWidth, height: scale * Layout.SecureHeader.iconHeight)
                .foregroundColor(Color(.accent))

            Text(Localization.transactionsSecure)
                .foregroundColor(Color(.text))
                .subheadlineStyle()

            Spacer()
        }
        .padding(.horizontal, Layout.SecureHeader.hPadding)
        .padding(.vertical, Layout.SecureHeader.vPadding)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var listView: some View {
        List {
            Section {
                ForEach(viewModel.paymentMethods) { method in
                    let selected: Bool = {
                        guard let selectedPaymentMethodID = viewModel.selectedPaymentMethodID else {
                            return false
                        }
                        return method.id == selectedPaymentMethodID
                    }()

                    HStack {
                        ZStack {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(.accent))
                                .renderedIf(selected)
                        }
                        .frame(width: Layout.ListView.checkmarkViewWidth)

                        VStack(alignment: .leading, spacing: Layout.ListView.textVSpacing) {
                            Text("\(method.info.type) ****\(method.info.lastDigits)")
                                .bodyStyle()

                            Text(method.info.cardholderName)
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                                .captionStyle()
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.didSelectPaymentMethod(withID: method.id)
                    }
                }
            } header: {
                Text(Localization.paymentMethodsHeader)
                    .textCase(.uppercase)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .captionStyle()
            } footer: {
                Text(String.localizedStringWithFormat(Localization.paymentMethodsFooter,
                                                      viewModel.WPCOMUsername,
                                                      viewModel.WPCOMEmail))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .captionStyle()
            }
        }
        .listStyle(.grouped)
    }

    @ViewBuilder
    private var noPaymentsView: some View {
        VStack(alignment: .center) {
            EmptyState(title: Localization.pleaseAddPaymentMethodMessage, image: .waitingForCustomersImage)

            Spacer()
        }
        .padding(.top, Layout.noPaymentsViewTopPadding)
    }
}

private extension BlazePaymentMethodsView {
    enum Localization {
        enum LoadPaymentMethodsErrorAlert {
            static let paymentMethods = NSLocalizedString(
                "blazePaymentMethodsView.loadPaymentMethodsErrorAlert.paymentMethods",
                value: "Error loading your payment methods",
                comment: "Error message indicating that loading payment methods failed"
            )
            static let cancel = NSLocalizedString(
                "blazePaymentMethodsView.loadPaymentMethodsErrorAlert.cancel",
                value: "Cancel",
                comment: "Dismiss button on the error alert displayed on the Blaze payment method list screen"
            )
            static let retry = NSLocalizedString(
                "blazePaymentMethodsView.loadPaymentMethodsErrorAlert.retry",
                value: "Retry",
                comment: "Button on the error alert displayed on the payment method list screen"
            )
        }
        static let navigationBarTitle = NSLocalizedString(
            "blazePaymentMethodsView.navigationBarTitle",
            value: "Payment Method",
            comment: "Navigation bar title in the Blaze Payment Method screen")
        static let cancelButton = NSLocalizedString(
            "blazePaymentMethodsView.cancelButton",
            value: "Cancel",
            comment: "Title of the button to dismiss the Blaze payment method list screen"
        )
        static let transactionsSecure = NSLocalizedString(
            "blazePaymentMethodsView.transactionsSecure",
            value: "All transactions are secure and encrypted",
            comment: "Text to explain that transactions will be secure in Payment Method screen"
        )
        static let paymentMethodsHeader = NSLocalizedString(
            "blazePaymentMethodsView.paymentMethodsHeader",
            value: "Payment Method Selected",
            comment: "Header for list of payment methods in Payment Method screen"
        )
        static let paymentMethodsFooter = NSLocalizedString(
            "blazePaymentMethodsView.paymentMethodsFooter",
            value: "Credits cards are retrieved from the following WordPress.com account: %1$@ <%2$@>",
            comment: "Footer for list of payment methods in Payment Method screen."
            + " %1$@ is a placeholder for the WordPress.com username."
            + " %2$@ is a placeholder for the WordPress.com email address."
        )
        static let emailReceipt = NSLocalizedString(
            "blazePaymentMethodsView.emailReceipt",
            value: "Email the label purchase receipts to %1$@ (%2$@) at %3$@",
            comment: "Label for the email receipts toggle in Payment Method screen."
            + " %1$@ is a placeholder for the account display name."
            + " %2$@ is a placeholder for the username."
            + " %3$@ is a placeholder for the WordPress.com email address."
        )
        static let addCreditCardButton = NSLocalizedString(
            "blazePaymentMethodsView.addCreditCardButton",
            value: "Add credit card",
            comment: "Button title in the Blaze Payment Method screen"
        )
        static let addAnotherCreditCardButton = NSLocalizedString(
            "blazePaymentMethodsView.addAnotherCreditCardButton",
            value: "Add another credit card",
            comment: "Button title in the Blaze Payment Method" +
            " screen if there is an existing payment method"
        )
        static let pleaseAddPaymentMethodMessage = NSLocalizedString(
            "blazePaymentMethodsView.pleaseAddPaymentMethodMessage",
            value: "Please add a new payment method",
            comment: "Message that will be displayed if there are no Blaze payment methods."
        )
    }

    enum Layout {
        enum SecureHeader {
            static let iconWidth: CGFloat = 18
            static let iconHeight: CGFloat = 20
            static let hSpacing: CGFloat = 8
            static let hPadding: CGFloat = 16
            static let vPadding: CGFloat = 12
        }
        static let noPaymentsViewTopPadding: CGFloat = 24

        enum ListView {
            static let checkmarkViewWidth: CGFloat = 32
            static let textVSpacing: CGFloat = 8
        }
        static let ctaPadding: CGFloat = 16
    }
}

struct BlazePaymentMethodsView_Previews: PreviewProvider {
    static var previews: some View {

        let viewModel = BlazePaymentMethodsViewModel(siteID: 123,
                                                     selectedPaymentMethodID: nil,
                                                     completion: { newPaymentID in
        })

        BlazePaymentMethodsView(viewModel: viewModel)

        let emptyPaymentsViewModel = BlazePaymentMethodsViewModel(siteID: 123,
                                                     selectedPaymentMethodID: nil,
                                                     completion: { newPaymentID in
        })

        BlazePaymentMethodsView(viewModel: emptyPaymentsViewModel)
            .previewDisplayName("No payment methods")
    }
}
