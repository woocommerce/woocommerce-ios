import SwiftUI

struct ShippingLabelPaymentMethods: View {
    @ObservedObject private var viewModel: ShippingLabelPaymentMethodsViewModel

    init(viewModel: ShippingLabelPaymentMethodsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ListHeaderView(text: Localization.paymentMethodsHeader, alignment: .left)
                    .textCase(.uppercase)

                ForEach(viewModel.paymentMethods, id: \.paymentMethodID) { method in
                    let selected = method == viewModel.selectedPaymentMethod
                    SelectableItemRow(title: "\(method.cardType.rawValue.capitalized) ****\(method.cardDigits)", subtitle: method.name, selected: selected)
                        .background(Color(.systemBackground))
                    Divider().padding(.leading, Constants.dividerPadding)
                }

                let settings = viewModel.accountSettings
                ListHeaderView(text: String.localizedStringWithFormat(Localization.paymentMethodsFooter,
                                                                      settings.storeOwnerWpcomUsername,
                                                                      settings.storeOwnerWpcomEmail),
                               alignment: .left)

                Spacer()
                    .frame(height: Constants.spacerHeight)

                TitleAndToggleRow(title: String.localizedStringWithFormat(Localization.emailReceipt,
                                                                          settings.storeOwnerDisplayName,
                                                                          settings.storeOwnerWpcomUsername,
                                                                          settings.storeOwnerWpcomEmail),
                                  isOn: $viewModel.isEmailReceiptsEnabled)
                    .background(Color(.systemBackground))
            }
        }
        .background(Color(.listBackground))
        .navigationBarItems(trailing: Button(action: {}, label: {
            Text(Localization.doneButton)
        }))
    }
}

private extension ShippingLabelPaymentMethods {
    enum Localization {
        static let paymentMethodsHeader = NSLocalizedString("Payment Method Selected", comment: "Header for list of payment methods in Payment Method screen")
        static let paymentMethodsFooter = NSLocalizedString("Credits cards are retrieved from the following WordPress.com account: %1$@ <%2$@>",
                                                            comment: "Footer for list of payment methods in Payment Method screen. Placeholders: %1$@ - username, %2$@ - email address")
        static let emailReceipt = NSLocalizedString("Email the label purchase receipts to %1$@ (%2$@) at %3$@",
                                                    comment: "Label for the email receipts toggle in Payment Method screen. Reads as: Email the label purchase receipts to {Full Name} ({username}) at {email address}")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Shipping Label Payment Method screen")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 48
        static let spacerHeight: CGFloat = 24
        static let rowPadding: CGFloat = 16
    }
}

struct ShippingLabelPaymentMethods_Previews: PreviewProvider {
    static var previews: some View {

        let viewModel = ShippingLabelPaymentMethodsViewModel(accountSettings: ShippingLabelPaymentMethodsViewModel.sampleAccountSettings(),
                                                             selectedPaymentMethod: ShippingLabelPaymentMethodsViewModel.samplePaymentMethods()[0])

        ShippingLabelPaymentMethods(viewModel: viewModel)
    }
}
