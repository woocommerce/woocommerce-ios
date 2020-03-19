
import Foundation

/// ViewModel for `OrdersViewController`.
///
/// This is an incremental WIP. Eventually, we should move all the data loading in here.
///
final class OrdersViewModel {
    enum SyncReason: String {
        case pullToRefresh = "pull_to_refresh"
    }
}
