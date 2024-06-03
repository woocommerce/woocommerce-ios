import SwiftUI
import NetworkingWatchOS

/// Loads an order form a notification
///
struct OrderDetailLoader: View {

    @StateObject var viewModel: OrderDetailLoaderViewModel

    init(dependencies: WatchDependencies, pushNotification: PushNotification) {
        _viewModel = StateObject(wrappedValue: OrderDetailLoaderViewModel(dependencies: dependencies, pushNotification: pushNotification))
    }

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle:
                Rectangle().hidden() // To properly trigger .task{} modifier
            case .loading:
                OrderDetailView(order: .placeholder)
                    .redacted(reason: .placeholder)
            case .loaded(let order):
                OrderDetailView(order: order)
            case .error:
                Text(AppLocalizedString(
                    "watch.notification.order.error",
                    value: "There was an error loading the notification",
                    comment: "Title when there is an error loading an order notification on the watch app"
                ))
            }
        }
        .task {
            await viewModel.fetchOrder()
        }
    }
}


/// View Model for the OrderDetailLoader
///
final class OrderDetailLoaderViewModel: ObservableObject {

    /// Represents the possible view states
    ///
    enum State {
        case idle
        case loading
        case loaded(order: OrdersListView.Order)
        case error
    }

    private let dependencies: WatchDependencies

    private let pushNotification: PushNotification

    @Published var viewState: State = .idle

    init(dependencies: WatchDependencies, pushNotification: PushNotification) {
        self.dependencies = dependencies
        self.pushNotification = pushNotification
    }

    /// Fetch order based on the provided push notification. Updates the view state as needed.
    ///
    func fetchOrder() async {
        self.viewState = .loading
        let dataService = OrderNotificationDataService(credentials: dependencies.credentials)
        do {
            let (_, remoteOrder) = try await dataService.loadOrderFrom(noteID: pushNotification.noteID)
            let viewOrders = OrdersListViewModel.viewOrders(from: [remoteOrder], currencySettings: dependencies.currencySettings)

            // Should always succeed.
            if let viewOrder = viewOrders.first {
                self.viewState = .loaded(order: viewOrder)
            } else {
                self.viewState = .error
            }
        } catch {
            self.viewState = .error
            DDLogError("⛔️ Could not fetch the order associated with the notification. \(error)")
        }
    }
}
