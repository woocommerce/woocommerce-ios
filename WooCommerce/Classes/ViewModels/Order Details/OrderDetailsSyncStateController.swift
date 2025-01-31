import Foundation

protocol OrderDetailsSyncStateControlling {
    var syncState: OrderDetailsSyncState { get set }
}

struct OrderDetailsSyncStateController: OrderDetailsSyncStateControlling {
    var syncState: OrderDetailsSyncState
}

/// Defines the possible sync states of the view model data.
///
enum OrderDetailsSyncState {
    case notSynced
    case synced
}
