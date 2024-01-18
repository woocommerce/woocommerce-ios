import SwiftUI

struct BlazePaymentMethodsView: View {
    @ObservedObject private var viewModel: BlazePaymentMethodsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddPaymentWebView: Bool = false

    init(viewModel: BlazePaymentMethodsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Payment Methods list
                    ListHeaderView(text: Localization.paymentMethodsHeader, alignment: .left)
                        .textCase(.uppercase)
                        .renderedIf(viewModel.paymentMethods.isNotEmpty)

                    // Empty state when there are no payments methods
                    VStack(alignment: .center) {
                        Spacer()
                            .frame(height: Layout.spacerHeight)
                        EmptyState(title: Localization.pleaseAddPaymentMethodMessage, image: .waitingForCustomersImage)
                    }
                    .renderedIf(viewModel.paymentMethods.isEmpty)

                    Divider()
                        .renderedIf(viewModel.paymentMethods.isNotEmpty)

                    ForEach(viewModel.paymentMethods) { method in
                        let selected: Bool = {
                            guard let selectedPaymentMethodID = viewModel.selectedPaymentMethodID else {
                                return false
                            }
                            return method.id == selectedPaymentMethodID
                        }()

                        SelectableItemRow(title: "\(method.type.rawValue.capitalized) ****\(method.info.lastDigits)",
                                          subtitle: method.name,
                                          selected: selected)
                        .onTapGesture {
                            viewModel.didSelectPaymentMethod(withID: method.id)
                        }
                        .background(Color(.systemBackground))

                        Divider()
                            .padding(.leading, Layout.dividerPadding)
                    }

                    ListHeaderView(text: String.localizedStringWithFormat(Localization.paymentMethodsFooter,
                                                                          viewModel.WPCOMUsername,
                                                                          viewModel.WPCOMEmail),
                                   alignment: .left)
                    .renderedIf(viewModel.paymentMethods.isNotEmpty)

                    Spacer()
                        .frame(height: Layout.spacerHeight)

                    Spacer()

                    // Add credit card button
                    let buttonText = viewModel.paymentMethods.isEmpty ? Localization.addCreditCardButton : Localization.addAnotherCreditCardButton

                    Button(action: {
                        showingAddPaymentWebView = true
                    }) {
                        Text(buttonText)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(Layout.controlPadding)
                }
            }
            .background(Color(.listBackground))
            .navigationTitle(Localization.navigationBarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        viewModel.saveSelection()
                        dismiss()
                    }, label: {
                        if viewModel.isFetchingPaymentInfo {
                            ProgressView()
                        } else {
                            Text(Localization.doneButton)
                        }
                    })
                    .disabled(!viewModel.isDoneButtonEnabled)
                }
            }
        }
        .sheet(isPresented: $showingAddPaymentWebView, content: {
            webView
        })
        .alert(Text(Localization.errorMessage), isPresented: $viewModel.shouldDisplayPaymentErrorAlert, actions: {
            Button(Localization.tryAgain) {
                Task {
                    await viewModel.syncPaymentInfo()
                }
            }
        })
    }

    @ViewBuilder
    private var webView: some View {
        if let addPaymentMethodURL = viewModel.addPaymentMethodURL,
           let fetchPaymentMethodURLPath = viewModel.addPaymentSuccessURL {
            NavigationView {
                AuthenticatedWebView(isPresented: $showingAddPaymentWebView,
                                     url: addPaymentMethodURL,
                                     urlToTriggerExit: fetchPaymentMethodURLPath) {
                    showingAddPaymentWebView = false
                    Task {
                        await viewModel.syncPaymentInfo()
                    }
                    let notice = Notice(title: Localization.paymentMethodAddedNotice, feedbackType: .success)
                    ServiceLocator.noticePresenter.enqueue(notice: notice)
                }
                                     .navigationTitle(Localization.paymentMethodWebViewTitle)
                                     .navigationBarTitleDisplayMode(.inline)
                                     .toolbar {
                                         ToolbarItem(placement: .confirmationAction) {
                                             Button(action: {
                                                 showingAddPaymentWebView = false
                                             }, label: {
                                                 Text(Localization.doneButtonAddPayment)
                                             })
                                         }
                                     }
            }
            .wooNavigationBarStyle()
        }
    }
}

private extension BlazePaymentMethodsView {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString(
            "blazePaymentMethodsView.navigationBarTitle",
            value: "Payment Method",
            comment: "Navigation bar title in the Blaze Payment Method screen")
        static let cancelButton = NSLocalizedString(
            "blazePaymentMethodsView.edit",
            value: "Cancel",
            comment: "Title of the button to dismiss the Blaze payment method list screen"
        )
        static let doneButton = NSLocalizedString(
            "blazePaymentMethodsView.doneButton",
            value: "Done",
            comment: "Done navigation button in the Blaze Payment Method screen"
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
            + " %2$@ is a placeholder for the WordPress.com email address.")
        static let emailReceipt = NSLocalizedString(
            "blazePaymentMethodsView.emailReceipt",
            value: "Email the label purchase receipts to %1$@ (%2$@) at %3$@",
            comment: "Label for the email receipts toggle in Payment Method screen."
            + " %1$@ is a placeholder for the account display name."
            + " %2$@ is a placeholder for the username."
            + " %3$@ is a placeholder for the WordPress.com email address.")
        static let addCreditCardButton = NSLocalizedString(
            "blazePaymentMethodsView.addCreditCardButton",
            value: "Add credit card",
            comment: "Button title in the Blaze Payment Method screen")
        static let addAnotherCreditCardButton = NSLocalizedString(
            "blazePaymentMethodsView.addAnotherCreditCardButton",
            value: "Add another credit card",
            comment: "Button title in the Blaze Payment Method" +
            " screen if there is an existing payment method")
        static let paymentMethodWebViewTitle = NSLocalizedString(
            "blazePaymentMethodsView.paymentMethodWebViewTitle",
            value: "Payment method",
            comment: "Title of the web view of adding a payment method in Blaze")
        static let doneButtonAddPayment = NSLocalizedString(
            "blazePaymentMethodsView.doneButtonAddPayment",
            value: "Done",
            comment: "Done navigation button in Blaze add payment web view")
        static let paymentMethodAddedNotice = NSLocalizedString(
            "blazePaymentMethodsView.paymentMethodAddedNotice",
            value: "Payment method added",
            comment: "Notice that will be displayed after adding a new Blaze payment method")
        static let pleaseAddPaymentMethodMessage = NSLocalizedString(
            "blazePaymentMethodsView.pleaseAddPaymentMethodMessage",
            value: "Please, add a new payment method",
            comment: "Message that will be displayed if there are no Blaze payment methods.")
        static let errorMessage = NSLocalizedString(
            "blazePaymentMethodsView.errorMessage",
            value: "Error loading your payment methods",
            comment: "Error message displayed when fetching payment methods failed on the Payment screen in the Blaze campaign creation flow."
        )
        static let tryAgain = NSLocalizedString(
            "blazePaymentMethodsView.tryAgain",
            value: "Try Again",
            comment: "Button to retry when fetching payment methods failed on the Payment screen in the Blaze campaign creation flow."
        )
    }

    enum Layout {
        static let dividerPadding: CGFloat = 48
        static let controlPadding: CGFloat = 16
        static let spacerHeight: CGFloat = 24
    }
}

struct BlazePaymentMethodsView_Previews: PreviewProvider {
    static var previews: some View {

        let viewModel = BlazePaymentMethodsViewModel(siteID: 123,
                                                     paymentInfo: BlazePaymentMethodsViewModel.samplePaymentInfo(),
                                                     selectedPaymentMethodID: nil,
                                                     completion: { newPaymentID in
        })

        BlazePaymentMethodsView(viewModel: viewModel)
            .colorScheme(.light)
            .previewDisplayName("Light mode")
    }
}
