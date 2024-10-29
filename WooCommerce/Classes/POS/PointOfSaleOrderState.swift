enum PointOfSaleOrderState: Equatable {
    case idle
    case syncing
    case loaded
    case error(PointOfSaleOrderSyncErrorMessageViewModel)

    static func == (lhs: PointOfSaleOrderState, rhs: PointOfSaleOrderState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
            (.syncing, .syncing),
            (.loaded, .loaded),
            (.error, .error):
            return true
        default:
            return false
        }
    }

    var isSyncing: Bool {
        switch self {
        case .syncing:
            return true
        default:
            return false
        }
    }

    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }

    var isError: Bool {
        switch self {
        case .error:
            return true
        default:
            return false
        }
    }
}
