import SwiftUI

struct CustomersListView: View {
    @StateObject var viewModel: CustomersListViewModel

    var body: some View {
        Group {
            switch viewModel.syncState {
            case .results:
                RefreshableInfiniteScrollList(isLoading: viewModel.shouldShowBottomActivityIndicator,
                                              loadAction: viewModel.onLoadNextPageAction,
                                              refreshAction: { completion in
                    viewModel.onRefreshAction(completion: completion)
                }) {
                    ForEach(viewModel.customers, id: \.customerID) { customer in
                        VStack(spacing: 0) {
                            LazyNavigationLink(destination: CustomerDetailView(viewModel: .init(customer: customer)), label: {
                                HStack {
                                    TitleAndSubtitleAndDetailRow(title: viewModel.displayName(for: customer),
                                                                 detail: viewModel.displayUsername(for: customer),
                                                                 subtitle: viewModel.displayEmail(for: customer),
                                                                 subtitlePlaceholder: Localization.emailPlaceholder)
                                    DisclosureIndicator()
                                }
                                .padding()
                                .background(Color(.listForeground(modal: false)))
                            })

                            Divider().padding(.leading)
                        }
                    }
                }
            case .syncingFirstPage:
                List {
                    ForEach(CustomersListViewModel.placeholderRows, id: \.customerID) { customer in
                        TitleAndSubtitleAndDetailRow(title: customer.name ?? "",
                                                     detail: customer.username,
                                                     subtitle: customer.email,
                                                     subtitlePlaceholder: Localization.emailPlaceholder)
                        .redacted(reason: .placeholder)
                        .shimmering()
                    }
                }
            case .empty:
                EmptyState(title: Localization.emptyStateTitle,
                           description: Localization.emptyStateMessage,
                           image: .cashRegisterImage)
                    .frame(maxHeight: .infinity)
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .wooNavigationBarStyle()
        .onAppear {
            viewModel.loadCustomers()
        }
    }
}

private extension CustomersListView {
    enum Localization {
        static let title = NSLocalizedString("customersList.title",
                                             value: "Customers",
                                             comment: "Title for Customers list screen")
        static let emailPlaceholder = NSLocalizedString("customersList.emailPlaceholder",
                                                        value: "No email address",
                                                        comment: "Placeholder for a customer with no email address in the Customers list screen.")
        static let emptyStateTitle = NSLocalizedString("customerList.emptyStateTitle",
                                                       value: "No customers yet",
                                                       comment: "Title when there are no customers to show in the Customers list screen.")
        static let emptyStateMessage = NSLocalizedString("customerList.emptyStateMessage",
                                                         value: "Create an order to start gathering customer insights",
                                                         comment: "Message when there are no customers to show in the Customers list screen.")
    }
}

#Preview {
    CustomersListView(viewModel: .init(siteID: 0))
}
