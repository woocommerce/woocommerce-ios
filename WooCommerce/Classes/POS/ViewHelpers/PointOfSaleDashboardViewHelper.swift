import Foundation
import SwiftUI

struct PointOfSaleDashboardViewHelper {
    static func determineViewState(
        eligibilityState: POSEligibilityState?,
        itemsContainerState: ItemsContainerState,
        horizontalSizeClass: UserInterfaceSizeClass?
    ) -> PointOfSaleDashboardView.ViewState {
        guard case .regular = horizontalSizeClass else {
            return .unsupportedWidth
        }

        guard let eligibilityState else {
            return .loading
        }

        switch eligibilityState {
        case .eligible:
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
        case .loading, .ineligible:
            return false
        }
    }
}
