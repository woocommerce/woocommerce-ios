import SwiftUI

/// Entry point for the order list view
///
struct OrdersListView: View {

    // Used to changed the tab programmatically
    @Binding var watchTab: WooWatchTab

    // View Model to drive the view
    @StateObject var viewModel: OrdersListViewModel

    init(dependencies: WatchDependencies, watchTab: Binding<WooWatchTab>) {
        _viewModel = StateObject(wrappedValue: OrdersListViewModel(dependencies: dependencies))
        self._watchTab = watchTab
    }

    var body: some View {
        NavigationStack() {
            Group {
                switch viewModel.viewState {
                case .idle:
                    EmptyView()
                case .loading:
                    loadingView
                case .error:
                    errorView
                case .loaded(let orders):
                    dataView(orders: orders)
                }
            }
            .navigationTitle(Localization.title)
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
        }
        .task {
            await viewModel.fetchOrders()
        }
    }

    /// Loading: Redacted OrderListCard
    ///
    @ViewBuilder var loadingView: some View {
        List {
            OrderListCard(order: .placeholder)
        }
        .redacted(reason: .placeholder)
    }

    /// Error View with a retry button
    ///
    @ViewBuilder var errorView: some View {
        VStack {
            Spacer()
            Text(Localization.error)
            Spacer()
            Button(Localization.retry) {
                Task {
                    await viewModel.fetchOrders()
                }
            }
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
        static let error = AppLocalizedString(
            "watch.orders.error.title",
            value: "There was an error loading the orders list",
            comment: "Loading title on the watch orders list screen."
        )
        static let retry = AppLocalizedString(
            "watch.orders.retry.title",
            value: "Retry",
            comment: "Retry on the watch orders list screen."
        )
    }

    enum Images {
        static let myStore = Image(systemName: "house")
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
        static let wooPurple20 = Color(red: 190/255.0, green: 160/255.0, blue: 242/255.0)
        static let wooBackgroundStart = Color(red: 69/255.0, green: 43/255.0, blue: 100/255.0)
        static let wooBackgroundEnd = Color(red: 49/255.0, green: 31/255.0, blue: 71/255.0)
    }
}
