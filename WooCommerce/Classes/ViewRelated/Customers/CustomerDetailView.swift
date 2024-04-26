import SwiftUI

struct CustomerDetailView: View {
    let viewModel: CustomerDetailViewModel

    @State private var isPresentingEmailDialog: Bool = false
    @State private var isShowingEmailView: Bool = false

    var body: some View {
        List {
            Section(header: Text(Localization.customerSection)) {
                Text(viewModel.name)
                HStack {
                    Text(viewModel.email ?? Localization.emailPlaceholder)
                        .style(for: viewModel.email)
                    Spacer()
                    Button {
                        isPresentingEmailDialog.toggle()
                        viewModel.trackEmailMenuTapped()
                    } label: {
                        Image(uiImage: .mailImage)
                            .foregroundColor(Color(.primary))
                    }
                    .accessibilityLabel(Localization.emailAction)
                    .renderedIf(viewModel.email != nil)
                    .confirmationDialog(Localization.emailAction, isPresented: $isPresentingEmailDialog) {
                        Button(Localization.sendEmail) {
                            isShowingEmailView.toggle()
                            viewModel.trackEmailOptionTapped()
                        }
                        .renderedIf(EmailView.canSendEmail())

                        Button(Localization.copyEmail) {
                            viewModel.copyEmail()
                        }
                    }
                }
                customerDetailRow(label: Localization.dateLastActiveLabel, value: viewModel.dateLastActive)
            }

            Section(header: Text(Localization.ordersSection)) {
                customerDetailRow(label: Localization.ordersCountLabel, value: viewModel.ordersCount)
                customerDetailRow(label: Localization.totalSpendLabel, value: viewModel.totalSpend)
                customerDetailRow(label: Localization.avgOrderValueLabel, value: viewModel.avgOrderValue)
            }

            Section(header: Text(Localization.registrationSection)) {
                customerDetailRow(label: Localization.usernameLabel, value: viewModel.username)
                customerDetailRow(label: Localization.dateRegisteredLabel, value: viewModel.dateRegistered)
            }

            Section(header: Text(Localization.locationSection)) {
                customerDetailRow(label: Localization.countryLabel, value: viewModel.country)
                customerDetailRow(label: Localization.regionLabel, value: viewModel.region)
                customerDetailRow(label: Localization.cityLabel, value: viewModel.city)
                customerDetailRow(label: Localization.postcodeLabel, value: viewModel.postcode)
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .listBackground))
        .navigationTitle(viewModel.name)
        .navigationBarTitleDisplayMode(.inline)
        .wooNavigationBarStyle()
        .sheet(isPresented: $isShowingEmailView) {
            EmailView(emailAddress: viewModel.email)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

private extension CustomerDetailView {
    @ViewBuilder func customerDetailRow(label: String, value: String?) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value ?? Localization.defaultPlaceholder)
                .style(for: value)
        }
    }
}

private extension Text {
    /// Styles the text based on whether there is a provided value.
    ///
    @ViewBuilder func style(for value: String?) -> some View {
        if value != nil {
            self.bodyStyle()
        } else {
            self.secondaryBodyStyle()
        }
    }
}

private extension CustomerDetailView {
    enum Localization {
        static let customerSection = NSLocalizedString("customerDetailView.customerSection",
                                                       value: "CUSTOMER",
                                                       comment: "Heading for the section with general customer details in the Customer Details screen.")
        static let dateLastActiveLabel = NSLocalizedString("customerDetailView.dateLastActiveLabel",
                                                      value: "Last active",
                                                      comment: "Label for the date the customer was last active in the Customer Details screen.")

        static let ordersSection = NSLocalizedString("customerDetailView.ordersSection",
                                                       value: "ORDERS",
                                                       comment: "Heading for the section with customer order stats in the Customer Details screen.")
        static let ordersCountLabel = NSLocalizedString("customerDetailView.ordersCountLabel",
                                                        value: "Orders",
                                                        comment: "Label for the number of orders in the Customer Details screen.")
        static let totalSpendLabel = NSLocalizedString("customerDetailView.totalSpendLabel",
                                                       value: "Total spend",
                                                       comment: "Label for the customer's total spend in the Customer Details screen.")
        static let avgOrderValueLabel = NSLocalizedString("customerDetailView.avgOrderValueLabel",
                                                          value: "Average order value",
                                                          comment: "Label for the customer's average order value in the Customer Details screen.")

        static let registrationSection = NSLocalizedString("customerDetailView.registrationSection",
                                                       value: "REGISTRATION",
                                                       comment: "Heading for the section with customer registration details in the Customer Details screen.")
        static let usernameLabel = NSLocalizedString("customerDetailView.usernameLabel",
                                                       value: "Username",
                                                       comment: "Label for the customer's username in the Customer Details screen.")
        static let dateRegisteredLabel = NSLocalizedString("customerDetailView.dateRegisteredLabel",
                                                          value: "Date registered",
                                                          comment: "Label for the customer's registration date in the Customer Details screen.")

        static let locationSection = NSLocalizedString("customerDetailView.locationSection",
                                                       value: "LOCATION",
                                                       comment: "Heading for the section with customer location details in the Customer Details screen.")
        static let countryLabel = NSLocalizedString("customerDetailView.countryLabel",
                                                       value: "Country",
                                                       comment: "Label for the customer's country in the Customer Details screen.")
        static let regionLabel = NSLocalizedString("customerDetailView.regionLabel",
                                                        value: "Region",
                                                        comment: "Label for the customer's region in the Customer Details screen.")
        static let cityLabel = NSLocalizedString("customerDetailView.cityLabel",
                                                       value: "City",
                                                       comment: "Label for the customer's city in the Customer Details screen.")
        static let postcodeLabel = NSLocalizedString("customerDetailView.postcodeLabel",
                                                          value: "Postal code",
                                                          comment: "Label for the customer's postal code in the Customer Details screen.")

        static let defaultPlaceholder = NSLocalizedString("customerDetailView.defaultPlaceholder",
                                                          value: "None",
                                                          comment: "Default placeholder if a customer's details are not available in the Customer Details screen.")
        static let emailPlaceholder = NSLocalizedString("customerDetailView.emailPlaceholder",
                                                          value: "No email address",
                                                          comment: "Placeholder if a customer's email address is not available in the Customer Details screen.")

        static let emailAction = NSLocalizedString("customerDetailView.emailActionLabel",
                                                   value: "Contact customer via email",
                                                   comment: "Title for action to contact a customer via email.")
        static let sendEmail = NSLocalizedString("customerDetailView.sendEmail",
                                                 value: "Email",
                                                 comment: "Button to email a customer in the Customer Details screen.")
        static let copyEmail = NSLocalizedString("customerDetailView.copyEmail",
                                                 value: "Copy email address",
                                                 comment: "Button to copy a customer's email address in the Customer Details screen.")
    }
}

#Preview("Customer") {
    CustomerDetailView(viewModel: CustomerDetailViewModel(name: "Pat Smith",
                                                          dateLastActive: "Jan 1, 2024",
                                                          email: "patsmith@example.com",
                                                          ordersCount: "3",
                                                          totalSpend: "$81.75",
                                                          avgOrderValue: "$27.25",
                                                          username: "patsmith",
                                                          dateRegistered: "Jan 1, 2023",
                                                          country: "United States",
                                                          region: "Oregon",
                                                          city: "Portland",
                                                          postcode: "12345"))
}

#Preview("Customer with Placeholders") {
    CustomerDetailView(viewModel: CustomerDetailViewModel(name: "Guest",
                                                          dateLastActive: "Jan 1, 2024",
                                                          email: nil,
                                                          ordersCount: "0",
                                                          totalSpend: "$0.00",
                                                          avgOrderValue: "$0.00",
                                                          username: nil,
                                                          dateRegistered: nil,
                                                          country: nil,
                                                          region: nil,
                                                          city: nil,
                                                          postcode: nil))
}
