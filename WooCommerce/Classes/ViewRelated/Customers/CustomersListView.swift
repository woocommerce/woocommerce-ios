import SwiftUI

struct CustomersListView: View {
    @StateObject var viewModel = CustomersListViewModel()

    var body: some View {
        List {
            ForEach(viewModel.customers, id: \.customerID) { customer in
                HStack {
                    TitleAndSubtitleAndDetailRow(title: customer.name ?? Localization.guestLabel,
                                                 detail: customer.username,
                                                 subtitle: customer.email,
                                                 subtitlePlaceholder: Localization.emailPlaceholder)
                    DisclosureIndicator()
                }
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .wooNavigationBarStyle()
    }
}

private extension CustomersListView {
    enum Localization {
        static let title = NSLocalizedString("customersList.title",
                                             value: "Customers",
                                             comment: "Title for Customers list screen")
        static let guestLabel = NSLocalizedString("customersList.guestLabel",
                                                  value: "Guest",
                                                  comment: "Label for a customer with no name in the Customers list screen.")
        static let emailPlaceholder = NSLocalizedString("customersList.emailPlaceholder",
                                                        value: "No email address",
                                                        comment: "Placeholder for a customer with no email address in the Customers list screen.")
    }
}

#Preview {
    CustomersListView()
}
