import SwiftUI
import Yosemite

struct ShippingLabelPaymentMethods: View {
    @ObservedObject private var viewModel: ShippingLabelPaymentMethodsViewModel
    @Environment(\.presentationMode) var presentation
    @State private var showingAddPaymentWebView: Bool = false

    /// Completion callback
    ///
    typealias Completion = (_ newAccountSettings: ShippingLabelAccountSettings) -> Void
    private let onCompletion: Completion

    init(viewModel: ShippingLabelPaymentMethodsViewModel, completion: @escaping Completion) {
        self.viewModel = viewModel
        onCompletion = completion
        ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "payment_method_started"])
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Banner displayed when user can't edit payment methods
                    let bannerEdgeInsets = EdgeInsets(top: 0, leading: geometry.safeAreaInsets.leading, bottom: 0, trailing: geometry.safeAreaInsets.trailing)
                    ShippingLabelPaymentMethodsTopBanner(width: geometry.size.width,
                                                         edgeInsets: bannerEdgeInsets,
                                                         storeOwnerDisplayName: viewModel.storeOwnerDisplayName,
                                                         storeOwnerUsername:
                                                            viewModel.storeOwnerUsername)
                        .renderedIf(!viewModel.canEditPaymentMethod)

                    // Payment Methods list
                    ListHeaderView(text: Localization.paymentMethodsHeader, alignment: .left)
                        .textCase(.uppercase)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .renderedIf(viewModel.paymentMethods.isNotEmpty)

                    // Empty state when there are no payments methods
                    VStack(alignment: .center) {
                        Spacer()
                            .frame(height: Constants.spacerHeight)
                        EmptyState(title: Localization.pleaseAddPaymentMethodMessage, image: .waitingForCustomersImage)
                    }
                    .renderedIf(viewModel.paymentMethods.isEmpty)

                    Divider()
                        .renderedIf(viewModel.paymentMethods.isNotEmpty)

                    ForEach(viewModel.paymentMethods, id: \.paymentMethodID) { method in
                        let selected = method.paymentMethodID == viewModel.selectedPaymentMethodID
                        SelectableItemRow(title: "\(method.cardType.rawValue.capitalized) ****\(method.cardDigits)",
                                          subtitle: method.name,
                                          selected: selected)
                            .onTapGesture {
                                viewModel.didSelectPaymentMethod(withID: method.paymentMethodID)
                            }
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                            .background(Color(.systemBackground))
                        Divider().padding(.leading, Constants.dividerPadding)
                    }
                    .disabled(!viewModel.canEditPaymentMethod)

                    ListHeaderView(text: String.localizedStringWithFormat(Localization.paymentMethodsFooter,
                                                                          viewModel.storeOwnerWPcomUsername,
                                                                          viewModel.storeOwnerWPcomEmail),
                                   alignment: .left)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .renderedIf(viewModel.paymentMethods.isNotEmpty)

                    Spacer()
                        .frame(height: Constants.spacerHeight)

                    // Email Receipts setting toggle
                    TitleAndToggleRow(title: String.localizedStringWithFormat(Localization.emailReceipt,
                                                                              viewModel.storeOwnerDisplayName,
                                                                              viewModel.storeOwnerUsername,
                                                                              viewModel.storeOwnerWPcomEmail),
                                      isOn: $viewModel.isEmailReceiptsEnabled)
                        .padding(Constants.controlPadding)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .background(Color(.systemBackground))
                        .disabled(!viewModel.canEditNonpaymentSettings)
                        .renderedIf(viewModel.paymentMethods.isNotEmpty)

                    Spacer()

                    // Add credit card button
                    if viewModel.canEditPaymentMethod && ServiceLocator.featureFlagService.isFeatureFlagEnabled(.shippingLabelsAddPaymentMethods) {

                        let buttonText = viewModel.paymentMethods.isEmpty ? Localization.addCreditCardButton : Localization.addAnotherCreditCardButton

                        Button(action: {
                            showingAddPaymentWebView = true
                            ServiceLocator.analytics.track(.shippingLabelAddPaymentMethodTapped)
                        }) {
                            HStack {
                                Spacer()
                                Text(buttonText)
                                Image(uiImage: .externalImage)
                                Spacer()
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(Constants.controlPadding)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .background(Color(.listBackground))
                    }
                }
                .padding(.bottom, insets: geometry.safeAreaInsets)
                .sheet(isPresented: $showingAddPaymentWebView, content: {
                    webview
                })
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .navigationBarTitle(Localization.navigationBarTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        viewModel.updateShippingLabelAccountSettings { newSettings in
                            ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "payment_method_selected"])
                            onCompletion(newSettings)
                            presentation.wrappedValue.dismiss()
                        }
                    }, label: {
                        if viewModel.isUpdating {
                            ProgressView()
                        } else {
                            Text(Localization.doneButton)
                        }
                    })
                    .disabled(!viewModel.isDoneButtonEnabled())
                }
            }
            .wooNavigationBarStyle()
        }
    }

    private var webview: some View {
        NavigationView {
            AuthenticatedWebView(isPresented: $showingAddPaymentWebView,
                                 url: WooConstants.URLs.addPaymentMethodWCShip.asURL(),
                                 urlToTriggerExit: viewModel.fetchPaymentMethodURLPath) {
                showingAddPaymentWebView = false
                viewModel.syncShippingLabelAccountSettings()
                ServiceLocator.analytics.track(.shippingLabelPaymentMethodAdded)
                let notice = Notice(title: Localization.paymentMethodAddedNotice, feedbackType: .success)
                ServiceLocator.noticePresenter.enqueue(notice: notice)
            }
            .navigationTitle(Localization.paymentMethodWebviewTitle)
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

private extension ShippingLabelPaymentMethods {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Payment Method", comment: "Navigation bar title in the Shipping Label Payment Method screen")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Shipping Label Payment Method screen")
        static let paymentMethodsHeader = NSLocalizedString("Payment Method Selected", comment: "Header for list of payment methods in Payment Method screen")
        static let paymentMethodsFooter =
            NSLocalizedString("Credits cards are retrieved from the following WordPress.com account: %1$@ <%2$@>",
                              comment: "Footer for list of payment methods in Payment Method screen."
                                + " %1$@ is a placeholder for the WordPress.com username."
                                + " %2$@ is a placeholder for the WordPress.com email address.")
        static let emailReceipt =
            NSLocalizedString("Email the label purchase receipts to %1$@ (%2$@) at %3$@",
                              comment: "Label for the email receipts toggle in Payment Method screen."
                                + " %1$@ is a placeholder for the account display name."
                                + " %2$@ is a placeholder for the username."
                                + " %3$@ is a placeholder for the WordPress.com email address.")
        static let addCreditCardButton = NSLocalizedString("Add credit card",
                                                           comment: "Button title in the Shipping Label Payment Method screen")
        static let addAnotherCreditCardButton = NSLocalizedString("Add another credit card",
                                                                  comment: "Button title in the Shipping Label Payment Method" +
                                                                    " screen if there is an existing payment method")
        static let paymentMethodWebviewTitle = NSLocalizedString("Payment method",
                                                            comment: "Title of the webview of adding a payment method in Shipping Labels")
        static let doneButtonAddPayment = NSLocalizedString("Done",
                                                            comment: "Done navigation button in Shipping Label add payment webview")
        static let paymentMethodAddedNotice = NSLocalizedString("Payment method added",
                                                                comment: "Notice that will be displayed after adding a new Shipping Label payment method")
        static let pleaseAddPaymentMethodMessage = NSLocalizedString("Please, add a new payment method",
                                                                     comment: "Message that will be displayed if there are no Shipping Label payment methods.")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 48
        static let controlPadding: CGFloat = 16
        static let spacerHeight: CGFloat = 24
    }
}

struct ShippingLabelPaymentMethods_Previews: PreviewProvider {
    static var previews: some View {

        let viewModel = ShippingLabelPaymentMethodsViewModel(accountSettings: ShippingLabelPaymentMethodsViewModel.sampleAccountSettings())

        let accountSettingsWithoutEditPermissions = ShippingLabelPaymentMethodsViewModel.sampleAccountSettings(withPermissions: false)
        let disabledViewModel = ShippingLabelPaymentMethodsViewModel(accountSettings: accountSettingsWithoutEditPermissions)

        ShippingLabelPaymentMethods(viewModel: viewModel, completion: { (newAccountSettings) in
        })
        .colorScheme(.light)
        .previewDisplayName("Light mode")

        ShippingLabelPaymentMethods(viewModel: viewModel, completion: { (newAccountSettings) in
        })
        .colorScheme(.dark)
        .previewDisplayName("Dark Mode")

        ShippingLabelPaymentMethods(viewModel: disabledViewModel, completion: { (newAccountSettings) in
        })
        .previewDisplayName("Disabled state")

        ShippingLabelPaymentMethods(viewModel: viewModel, completion: { (newAccountSettings) in
        })
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        .previewDisplayName("Accessibility: Large Font Size")

        ShippingLabelPaymentMethods(viewModel: viewModel, completion: { (newAccountSettings) in
        })
        .environment(\.layoutDirection, .rightToLeft)
        .previewDisplayName("Localization: Right-to-Left Layout")
    }
}
