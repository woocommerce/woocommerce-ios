import SwiftUI

/// Entry point for the order list view
///
struct OrdersListView: View {

    @Environment(\.appBindings) private var appBindings

    @EnvironmentObject private var tracksProvider: WatchTracksProvider

    // Used to changed the tab programmatically
    @Binding var watchTab: WooWatchTab

    // View Model to drive the view
    @StateObject var viewModel: OrdersListViewModel

    init(dependencies: WatchDependencies, watchTab: Binding<WooWatchTab>) {
        _viewModel = StateObject(wrappedValue: OrdersListViewModel(dependencies: dependencies))
        self._watchTab = watchTab
    }

    var body: some View {
        HStack {
            switch viewModel.viewState {
            case .idle:
                Rectangle().hidden()
                    .task {
                        await viewModel.fetchAndBindRefreshTrigger(trigger: appBindings.refreshData.eraseToAnyPublisher())
                    }
            case .loading:
                loadingView
            case .error:
                errorView
            case .loaded(let orders):
                if orders.isEmpty {
                    emptyStateView
                } else {
                    dataView(orders: orders)
                }
            }
        }
        .navigationTitle {
            Text(Localization.title)
                .foregroundStyle(OrderListCard.Colors.wooPurple5)
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    self.watchTab = .myStore
                } label: {
                    Images.myStore
                }
            }
        }
        .onAppear {
            tracksProvider.sendTracksEvent(.watchOrdersListOpened)
        }
    }

    /// Loading: Redacted OrderListCard
    ///
    @ViewBuilder var loadingView: some View {
        List {
            OrderListCard(order: .placeholder)
            OrderListCard(order: .placeholder)
        }
        .scrollDisabled(true)
        .redacted(reason: .placeholder)
    }

    /// Error View with a retry button
    ///
    @ViewBuilder var errorView: some View {
        VStack {
            ScrollView {
                Text(Localization.errorTitle)
                    .font(.caption)

                Spacer()

                Text(Localization.errorDescription)
                    .font(.footnote)

                Spacer()

            }
            .multilineTextAlignment(.center)

            Button(Localization.retry) {
                Task {
                    appBindings.refreshData.send()
                }
            }
            .padding(.bottom, -16)
        }
    }

    /// Empty State View.
    ///
    @ViewBuilder var emptyStateView: some View {
        VStack {
            Spacer()
            Text(Localization.empty)
            Spacer()
            Images.cart
                .resizable()
                .frame(maxWidth: Layout.cartSize, maxHeight: Layout.cartSize)
            Spacer()

        }
    }

    /// Data: List with live order content.
    ///
    @ViewBuilder private func dataView(orders: [Order]) -> some View {
        List() {
            ForEach(orders, id: \.number) { order in
                NavigationLink(value: order) {
                    OrderListCard(order: order)
                }
            }
            .listRowBackground(OrderListCard.background)
        }
        .navigationDestination(for: Order.self) { order in
            OrderDetailView(order: order)
        }
    }
}

private extension OrdersListView {
    enum Localization {
        static let title = AppLocalizedString(
            "watch.orders.title",
            value: "Orders",
            comment: "Title on the watch orders list screen."
        )
        static let errorTitle = AppLocalizedString(
            "watch.orders.error.title",
            value: "Failed to load orders",
            comment: "Error title on the watch orders list screen."
        )
        static let errorDescription = AppLocalizedString(
            "watch.orders.error.description",
            value: "Make sure your watch is connected to the internet and your phone is nearby.",
            comment: "Error description on the watch orders list screen."
        )
        static let retry = AppLocalizedString(
            "watch.orders.retry.title",
            value: "Retry",
            comment: "Retry on the watch orders list screen."
        )
        static let empty = AppLocalizedString(
            "watch.orders.empty.title",
            value: "Waiting for your first order!",
            comment: "Title on the watch orders list screen when there are no orders"
        )
    }

    enum Images {
        static let myStore = Image(systemName: "house")
        static let cart = Image(systemName: "cart")
    }

    enum Layout {
        static let cartSize = 40.0
    }
}

/// View that represents each Order Item in the list.
///
struct OrderListCard: View {

    let order: OrdersListView.Order

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {

            HStack {
                Text(order.date)
                Spacer()
                Text(order.number)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text(order.name)
                .font(.body)

            Text(order.total)
                .font(.body)
                .bold()

            Text(order.status)
                .font(.footnote)
                .foregroundStyle(Colors.wooPurple20)
        }
        .listRowBackground(Self.background)
    }

    static var background: some View {
        LinearGradient(gradient: Gradient(colors: [Colors.wooBackgroundStart, Colors.wooBackgroundEnd]), startPoint: .top, endPoint: .bottom)
            .cornerRadius(10)
    }
}

private extension OrderListCard {
    enum Colors {
        static let wooPurple5 = Color(red: 223/255.0, green: 209/255.0, blue: 251/255.0)
        static let wooPurple20 = Color(red: 190/255.0, green: 160/255.0, blue: 242/255.0)
        static let wooBackgroundStart = Color(red: 69/255.0, green: 43/255.0, blue: 100/255.0)
        static let wooBackgroundEnd = Color(red: 49/255.0, green: 31/255.0, blue: 71/255.0)
    }
}
