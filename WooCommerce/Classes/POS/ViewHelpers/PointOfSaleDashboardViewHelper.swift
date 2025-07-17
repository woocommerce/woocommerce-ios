import Foundation
import SwiftUI

@available(iOS 17.0, *)
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
