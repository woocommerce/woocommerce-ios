import SwiftUI

struct OrderCustomerSummary: View {

    let viewModel: NewOrderViewModel.CustomerDataViewModel

    @Environment(\.presentationMode) var presentation
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: Layout.sectionSpacing)
                contactsSection(title: viewModel.fullName, subtitle: viewModel.email)
                Spacer(minLength: Layout.sectionSpacing)
                addressSection(title: Localization.shippingAddressSection, address: viewModel.shippingAddressFormatted)
                Spacer(minLength: Layout.sectionSpacing)
                addressSection(title: Localization.billingAddressSection, address: viewModel.billingAddressFormatted)
            }
        }
        .background(Color(.listBackground).ignoresSafeArea())
        .ignoresSafeArea(.container, edges: [.horizontal])
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.closeButton) {
                    presentation.wrappedValue.dismiss()
                }
            }
        }
        .wooNavigationBarStyle()
    }
}

private extension OrderCustomerSummary {
    @ViewBuilder func contactsSection(title: String?, subtitle: String?) -> some View {
        ListHeaderView(text: Localization.contactSection, alignment: .left)
            .padding(.horizontal, insets: safeAreaInsets)
        Group {
            Divider()
            NavigationRow(content: {
                VStack(alignment: .leading, spacing: Layout.verticalEmailSpacing) {
                    if let title = title {
                        Text(title)
                            .bodyStyle()
                    }
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .footnoteStyle()
                    }
                }
            }, action: {})
            Divider()
        }
        .background(Color(.listForeground))
    }

    @ViewBuilder func addressSection(title: String, address: String?) -> some View {
        ListHeaderView(text: title, alignment: .left)
            .padding(.horizontal, insets: safeAreaInsets)
        Group {
            Divider()
            NavigationRow(content: {
                Text(address ?? Localization.emptyAddressPlaceholder)
                    .bodyStyle()
                    .multilineTextAlignment(.leading)
            }, action: {})
            Divider()
        }
        .background(Color(.listForeground))
    }

    enum Layout {
        static let sectionSpacing: CGFloat = 16.0
        static let verticalEmailSpacing: CGFloat = 4.0
    }

    enum Localization {
        static let title = NSLocalizedString("Customer", comment: "Title for the customer summary screen in order creation flow")
        static let closeButton = NSLocalizedString("Close", comment: "Title text of the button to dismiss customer summary screen")

        static let contactSection = NSLocalizedString("CONTACT", comment: "Details section title in the customer summary screen")
        static let shippingAddressSection = NSLocalizedString("SHIPPING ADDRESS", comment: "Details section title in the customer summary screen")
        static let billingAddressSection = NSLocalizedString("BILLING ADDRESS", comment: "Details section title in the customer summary screen")

        static let emptyAddressPlaceholder = NSLocalizedString("No address specified",
                                                               comment: "Placehodler for empty address value in the customer summary screen")
    }
}

struct OrderCustomerSummary_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NewOrderViewModel.CustomerDataViewModel(fullName: "Johnny Appleseed",
                                                                email: "scrambled@scrambled.com",
                                                                billingAddressFormatted: """
                                                                    Johnny Appleseed
                                                                    234 70th Street
                                                                    Niagara Falls NY 14304
                                                                    US
                                                                    """,
                                                                shippingAddressFormatted: nil)

        NavigationView {
            OrderCustomerSummary(viewModel: viewModel)
        }
    }
}
