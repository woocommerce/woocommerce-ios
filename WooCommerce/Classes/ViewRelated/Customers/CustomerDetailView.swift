import SwiftUI

struct CustomerDetailView: View {
    @StateObject private var viewModel: CustomerDetailViewModel

    @State private var isPresentingEmailDialog: Bool = false
    @State private var isShowingEmailView: Bool = false
    @State private var isPresentingPhoneDialog: Bool = false
    @State private var isShowingMessageView: Bool = false

    init(viewModel: CustomerDetailViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

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
                    .accessibilityLabel(Localization.ContactAction.emailAction)
                    .renderedIf(viewModel.email != nil)
                    .confirmationDialog(Localization.ContactAction.emailAction, isPresented: $isPresentingEmailDialog) {
                        Button(Localization.ContactAction.sendEmail) {
                            isShowingEmailView.toggle()
                            viewModel.trackEmailOptionTapped()
                        }
                        .renderedIf(EmailView.canSendEmail())

                        Button(Localization.ContactAction.copyEmail) {
                            viewModel.copyEmail()
                        }
                    }
                }
                HStack {
                    Text(viewModel.phone ?? Localization.phonePlaceholder)
                        .style(for: viewModel.phone)
                        .if(viewModel.isSyncing) { phone in
                            phone
                                .redacted(reason: .placeholder)
                                .shimmering()
                        }
                    Spacer()
                    if viewModel.phone != nil {
                        Button {
                            isPresentingPhoneDialog.toggle()
                            viewModel.trackPhoneMenuTapped()
                        } label: {
                            Image(uiImage: .ellipsisImage)
                                .foregroundColor(Color(.primary))
                        }
                        .accessibilityLabel(Localization.ContactAction.phoneAction)
                        .confirmationDialog(Localization.ContactAction.phoneAction, isPresented: $isPresentingPhoneDialog) {
                            Button(Localization.ContactAction.call) {
                                viewModel.callCustomer()
                            }
                            .renderedIf(viewModel.isPhoneCallAvailable)

                            Button(Localization.ContactAction.message) {
                                isShowingMessageView.toggle()
                                viewModel.trackMessageActionTapped()
                            }
                            .renderedIf(MessageComposeView.canSendMessage())

                            Button(Localization.ContactAction.copyPhoneNumber) {
                                viewModel.copyPhone()
                            }

                            Button(Localization.ContactAction.whatsapp) {
                                viewModel.sendWhatsappMessage()
                            }
                            .renderedIf(viewModel.isWhatsappAvailable)

                            Button(Localization.ContactAction.telegram) {
                                viewModel.sendTelegramMessage()
                            }
                            .renderedIf(viewModel.isTelegramAvailable)
                        }
                    }
                }
                customerDetailRow(label: Localization.dateLastActiveLabel, value: viewModel.dateLastActive)
            }

            Section {
                customerDetailRow(label: Localization.ordersCountLabel, value: viewModel.ordersCount)
                customerDetailRow(label: Localization.totalSpendLabel, value: viewModel.totalSpend)
                customerDetailRow(label: Localization.avgOrderValueLabel, value: viewModel.avgOrderValue)
            } header: {
                HStack {
                    Text(Localization.ordersSection)
                    Spacer()
                    Button {
                        viewModel.createNewOrder()
                    } label: {
                        Image(uiImage: .plusImage)
                    }
                    .accessibilityLabel(Localization.newOrder)
                    .renderedIf(viewModel.canCreateNewOrder)

                }
            }

            Section(header: Text(Localization.registrationSection)) {
                customerDetailRow(label: Localization.usernameLabel, value: viewModel.username)
                customerDetailRow(label: Localization.dateRegisteredLabel, value: viewModel.dateRegistered)
            }

            if let billing = viewModel.formattedBilling, billing.isNotEmpty {
                Section(header: Text(Localization.billingSection)) {
                    Text(billing)
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.copyBillingAddress()
                            } label: {
                                Text(Localization.ContactAction.copy)
                            }
                        }
                        .contextMenu {
                            Button {
                                viewModel.copyBillingAddress()
                            } label: {
                                Label(Localization.ContactAction.copy, systemImage: "doc.on.doc")
                            }
                        }
                }
            }
            if let shipping = viewModel.formattedShipping, shipping.isNotEmpty {
                Section(header: Text(Localization.shippingSection)) {
                    Text(shipping)
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.copyShippingAddress()
                            } label: {
                                Text(Localization.ContactAction.copy)
                            }
                        }
                        .contextMenu {
                            Button {
                                viewModel.copyShippingAddress()
                            } label: {
                                Label(Localization.ContactAction.copy, systemImage: "doc.on.doc")
                            }
                        }
                }
            }
            if viewModel.showLocation {
                Section(header: Text(Localization.locationSection)) {
                    customerDetailRow(label: Localization.countryLabel, value: viewModel.country)
                    customerDetailRow(label: Localization.regionLabel, value: viewModel.region)
                    customerDetailRow(label: Localization.cityLabel, value: viewModel.city)
                    customerDetailRow(label: Localization.postcodeLabel, value: viewModel.postcode)
                }
                .if(viewModel.isSyncing) { location in
                    location
                        .redacted(reason: .placeholder)
                        .shimmering()
                }
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
        .sheet(isPresented: $isShowingMessageView) {
            MessageComposeView(phone: viewModel.phone)
                .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            viewModel.syncCustomerAddressData()
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
        static let newOrder = NSLocalizedString("customerDetailsView.newOrderButton",
                                                value: "Create a new order",
                                                comment: "Label for button to create a new order for the customer in the Customer Details screen.")
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
        static let billingSection = NSLocalizedString("customerDetailView.billingSection",
                                                       value: "BILLING ADDRESS",
                                                       comment: "Heading for the section with customer billing address in the Customer Details screen.")
        static let shippingSection = NSLocalizedString("customerDetailView.shippingSection",
                                                       value: "SHIPPING ADDRESS",
                                                       comment: "Heading for the section with customer shipping address in the Customer Details screen.")
        static let phonePlaceholder = NSLocalizedString("customerDetailView.phonePlaceholder",
                                                        value: "No phone number",
                                                        comment: "Placeholder if a customer's phone number is not available in the Customer Details screen.")

        enum ContactAction {
            static let emailAction = NSLocalizedString("customerDetailView.emailActionLabel",
                                                       value: "Contact customer via email",
                                                       comment: "Title for action to contact a customer via email.")
            static let sendEmail = NSLocalizedString("customerDetailView.sendEmail",
                                                     value: "Email",
                                                     comment: "Button to email a customer in the Customer Details screen.")
            static let copyEmail = NSLocalizedString("customerDetailView.copyEmail",
                                                     value: "Copy email address",
                                                     comment: "Button to copy a customer's email address in the Customer Details screen.")
            static let copy = NSLocalizedString("customerDetailView.copyButton.label",
                                                value: "Copy",
                                                comment: "Copy address text button title — should be one word and as short as possible.")
            static let phoneAction = NSLocalizedString("customerDetailView.phoneActionLabel",
                                                       value: "Contact customer via phone",
                                                       comment: "Title for action to contact a customer via phone.")
            static let call = NSLocalizedString("customerDetailView.callPhoneNumber",
                                                value: "Call", comment: "Call phone number button title")
            static let message = NSLocalizedString("customerDetailView.messagePhoneNumber",
                                                   value: "Message", comment: "Message phone number button title")
            static let copyPhoneNumber = NSLocalizedString("customerDetailView.copyPhoneNumber",
                                                           value: "Copy number",
                                                           comment: "Button to copy phone number to clipboard")
            static let whatsapp = NSLocalizedString("customerDetailView.whatsapp",
                                                    value: "Send WhatsApp message",
                                                    comment: "Button to send a message to a customer via WhatsApp")
            static let telegram = NSLocalizedString("customerDetailView.telegram",
                                                    value: "Send Telegram message",
                                                    comment: "Button to send a message to a customer via Telegram")
        }
    }
}

#Preview("Customer") {
    CustomerDetailView(viewModel: CustomerDetailViewModel(siteID: 1,
                                                          customerID: 0,
                                                          name: "Pat Smith",
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
    CustomerDetailView(viewModel: CustomerDetailViewModel(siteID: 1,
                                                          customerID: 0,
                                                          name: "Guest",
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
