import Foundation
import SwiftUI

struct PointOfSaleDashboardViewHelper {
    static func determineViewState(
        eligibilityState: POSEligibilityState?,
        itemsContainerState: ItemsContainerState,
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
        case .eligible:
            // Check items container state
            switch itemsContainerState {
            case let .loading(isCatalogSyncing):
                return .loading(isCatalogSyncing: isCatalogSyncing)
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
        case .content, .unsupportedWidth:
            return true
        case .error(let error):
            // Hide floating controls for initial catalog sync errors
            // TODO: WOOMOB-1692 remove specialisation of errors if possible
            return error.errorType != .initialCatalogSyncError
        case .loading, .ineligible:
            return false
        }
    }
}
