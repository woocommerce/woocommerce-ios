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

        guard let eligibilityState else {
            return .loading(isCatalogSyncing: itemsContainerState.isCatalogSyncing)
        }

        switch eligibilityState {
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        case .eligible:
            switch itemsContainerState {
            case let .loading(isCatalogSyncing):
                return .loading(isCatalogSyncing: isCatalogSyncing)
            case .error(let error):
                return .error(error)
            case .content:
                if pinStatus == .unknown && !isStaffRefreshing {
                    return .error(.errorOnLoadingStaff())
                }
                if pinStatus == .unknown {
                    return .loading()
                }
                if isLocked && pinStatus == .present {
                    return .locked
                }
                return .content
            }
        }
    }
}

extension PointOfSaleDashboardView.ViewState {
    var showsFloatingControl: Bool {
        switch self {
        case .content, .unsupportedWidth:
            return true
        case .error(let error):
            // TODO: WOOMOB-1692 remove specialisation of errors if possible
            return error.errorType != .initialCatalogSyncError && error.errorType != .staffLoadError
        case .loading, .ineligible, .locked:
            return false
        }
    }
}
