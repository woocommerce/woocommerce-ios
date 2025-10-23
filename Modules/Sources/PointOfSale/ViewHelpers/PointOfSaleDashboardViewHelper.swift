import Foundation
import SwiftUI
import enum Yosemite.POSCatalogSyncState

struct PointOfSaleDashboardViewHelper {
    static func determineViewState(
        eligibilityState: POSEligibilityState?,
        itemsContainerState: ItemsContainerState,
        horizontalSizeClass: UserInterfaceSizeClass?,
        catalogSyncState: POSCatalogSyncState?
    ) -> PointOfSaleDashboardView.ViewState {

        /// Check first to show syncing state as soon as possible
        if let syncState = catalogSyncState {
            switch syncState {
            case .syncStarted(_, true):
                return .catalogSyncing
            case .syncNeverDone:
                return .catalogSyncing
            case .syncStarted(_, false):
                // Non-initial sync, continue to other checks
                break
            case .syncCompleted:
                // Continue to other checks
                break
            case .syncFailed:
                return .error(PointOfSaleErrorState.errorOnLoadingOrders())
            }
        }

        guard case .regular = horizontalSizeClass else {
            return .unsupportedWidth
        }

        guard let eligibilityState else {
            return .loading
        }

        switch eligibilityState {
        case .eligible:
            // Check items container state
            switch itemsContainerState {
            case .loading:
                return .loading
            case .error(let error):
                return .error(error)
            case .content:
                return .content
            }
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }
    }
}

extension PointOfSaleDashboardView.ViewState {
    var showsFloatingControl: Bool {
        switch self {
        case .content, .error, .unsupportedWidth:
            return true
        case .loading, .ineligible, .catalogSyncing:
            return false
        }
    }
}
