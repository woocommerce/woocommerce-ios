import Foundation
import SwiftUI

struct PointOfSaleDashboardViewHelper {
    static func determineViewState(
        eligibilityState: POSEligibilityState?,
        itemsContainerState: ItemsContainerState,
        pinStatus: POSPINStatus,
        isLocked: Bool,
        isStaffRefreshing: Bool,
        horizontalSizeClass: UserInterfaceSizeClass?,
        isPhonePrototypeEnabled: Bool
    ) -> PointOfSaleDashboardView.ViewState {

        guard isPhonePrototypeEnabled || horizontalSizeClass == .regular else {
            return .unsupportedWidth
        }

        // Staff gate first. Until pinStatus resolves, we can't safely show POS content -
        // an unresolved cold cache must keep gating access (see DefaultPOSAccessSession).
        // .unknown + not refreshing means the fetch finished without a cache fallback;
        // surface as an error so the user can retry.
        if pinStatus == .unknown && !isStaffRefreshing {
            return .error(.errorOnLoadingStaff())
        }
        if pinStatus == .unknown {
            return .loading(isCatalogSyncing: itemsContainerState.isCatalogSyncing)
        }

        guard let eligibilityState else {
            return .loading(isCatalogSyncing: itemsContainerState.isCatalogSyncing)
        }

        switch eligibilityState {
        case .eligible:
            switch itemsContainerState {
            case let .loading(isCatalogSyncing):
                return .loading(isCatalogSyncing: isCatalogSyncing)
            case .error(let error):
                return .error(error)
            case .content:
                // Lock gate goes last: only after every other readiness check has passed,
                // so the lock screen only appears when the dashboard would otherwise be
                // interactive. pinStatus == .absent skips the lock entirely (no PIN system
                // configured for this site).
                if isLocked && pinStatus == .present {
                    return .locked
                }
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
        case .content, .unsupportedWidth:
            return true
        case .error(let error):
            // Hide floating controls for initial catalog sync errors
            // TODO: WOOMOB-1692 remove specialisation of errors if possible
            return error.errorType != .initialCatalogSyncError && error.errorType != .staffLoadError
        case .loading, .ineligible, .locked:
            return false
        }
    }
}
