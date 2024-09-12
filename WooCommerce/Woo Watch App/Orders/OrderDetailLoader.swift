import SwiftUI
import NetworkingWatchOS

/// Loads an order form a notification
///
struct OrderDetailLoader: View {

    @StateObject var viewModel: OrderDetailLoaderViewModel
    private let pushNotification: PushNotification
    private let network: Network

    init(dependencies: WatchDependencies, pushNotification: PushNotification,
         network: Network) {
        _viewModel = StateObject(wrappedValue: OrderDetailLoaderViewModel(dependencies: dependencies, pushNotification: pushNotification))
        self.pushNotification = pushNotification
        self.network = network
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
                    .task {
                        _ = await viewModel.markOrderNoteAsReadIfNeeded(noteID: pushNotification.noteID,
                                                                        orderID: Int(order.orderID))
                    }
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
    private let dataService: OrderNotificationDataService

    @Published var viewState: State = .idle

    init(dependencies: WatchDependencies, pushNotification: PushNotification) {
        self.dependencies = dependencies
        self.pushNotification = pushNotification
        self.dataService = OrderNotificationDataService(credentials: dependencies.credentials)
    }

    func markOrderNoteAsReadIfNeeded(noteID: Int64, orderID: Int) async -> Result<Int64, MarkOrderAsReadUseCase.Error> {
        return await dataService.markOrderNoteAsReadIfNeeded(noteID: noteID, orderID: orderID)
    }

    /// Fetch order based on the provided push notification. Updates the view state as needed.
    ///
    func fetchOrder() async {
        self.viewState = .loading
        do {
            let (_, remoteOrder) = try await dataService.loadOrderFrom(notification: pushNotification)
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
