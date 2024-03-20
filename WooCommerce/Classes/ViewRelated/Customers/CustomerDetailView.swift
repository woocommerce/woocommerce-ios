import SwiftUI

struct CustomerDetailView: View {
    /// Customer name
    let name: String

    /// Date the customer was last active
    let lastActiveDate: String

    /// Customer email
    let email: String

    /// Number of orders from the customer
    let ordersCount: String

    /// Customer's total spend
    let totalSpend: String

    /// Customer's average order value
    let avgOrderValue: String

    /// Customer username
    let username: String

    /// Date the customer was registered on the store
    let dateRegistered: String

    /// Customer country
    let country: String

    /// Customer region
    let region: String

    /// Customer city
    let city: String

    /// Customer postal code
    let postcode: String

    var body: some View {
        List {
            Section(header: Text(Localization.customerSection)) {
                Text(name)
                Text(email)
                customerDetailRow(label: Localization.lastActiveDateLabel, value: lastActiveDate)
            }

            Section(header: Text(Localization.ordersSection)) {
                customerDetailRow(label: Localization.ordersCountLabel, value: ordersCount)
                customerDetailRow(label: Localization.totalSpendLabel, value: totalSpend)
                customerDetailRow(label: Localization.avgOrderValueLabel, value: avgOrderValue)
            }

            Section(header: Text(Localization.registrationSection)) {
                customerDetailRow(label: Localization.usernameLabel, value: username)
                customerDetailRow(label: Localization.dateRegisteredLabel, value: dateRegistered)
            }

            Section(header: Text(Localization.locationSection)) {
                customerDetailRow(label: Localization.countryLabel, value: country)
                customerDetailRow(label: Localization.regionLabel, value: region)
                customerDetailRow(label: Localization.cityLabel, value: city)
                customerDetailRow(label: Localization.postcodeLabel, value: postcode)
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .listBackground))
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .wooNavigationBarStyle()
    }
}

private extension CustomerDetailView {
    @ViewBuilder
    func customerDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
    }
}

private extension CustomerDetailView {
    enum Localization {
        static let customerSection = NSLocalizedString("customerDetailView.customerSection",
                                                       value: "CUSTOMER",
                                                       comment: "Heading for the section with general customer details in the Customer Details screen.")
        static let lastActiveDateLabel = NSLocalizedString("customerDetailView.lastActiveDateLabel",
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
    }
}

#Preview {
    CustomerDetailView(name: "Pat Smith",
                       lastActiveDate: "1/1/24",
                       email: "patsmith@example.com",
                       ordersCount: "3",
                       totalSpend: "$81",
                       avgOrderValue: "$27",
                       username: "patsmith",
                       dateRegistered: "1/1/23",
                       country: "United States",
                       region: "Oregon",
                       city: "Portland",
                       postcode: "12345")
}
