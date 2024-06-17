import Foundation
import UIKit

enum NotificationBadgeType {
    case primary
    case secondary

    var color: UIColor {
        switch self {
        case .primary:
            return .accent
        case .secondary:
            return .primary
        }
    }
}

enum NotificationBadgeActionType {
    case show(type: NotificationBadgeType)
    case hide
}

/// Gathers the necessary data to update the badge on a tabbar tab
struct NotificationsBadgeInput {
    let action: NotificationBadgeActionType
    let tab: WooTab
    let tabBar: UITabBar
    let tabIndex: Int
}

@MainActor
final class NotificationsBadgeController {
    /// Updates the tab badge depending on the provided input parameter
    ///
    func updateBadge(with input: NotificationsBadgeInput) {
        switch input.action {
        case .show:
            showDotOn(with: input)
        case .hide:
            hideDotOn(with: input)
        }
    }


    /// Shows the dot in the specified WooTab
    ///
    private func showDotOn(with input: NotificationsBadgeInput) {
        guard case let .show(type) = input.action else {
            return

        }
        hideDotOn(with: input)
        let dot = DotView(frame: CGRect(x: DotConstants.xOffset,
                                        y: DotConstants.yOffset,
                                        width: DotConstants.diameter,
                                        height: DotConstants.diameter),
                          color: type.color,
                          borderWidth: DotConstants.borderWidth)
        dot.tag = dotTag(for: input.tab)
        dot.isHidden = true
        input.tabBar.orderedTabBarActionableViews[input.tabIndex].subviews.first?.insertSubview(dot, at: 1)
        dot.fadeIn()
    }

    /// Hides the Dot in the specified WooTab
    ///
    private func hideDotOn(with input: NotificationsBadgeInput) {
        let tag = dotTag(for: input.tab)
        if let subviews = input.tabBar.orderedTabBarActionableViews[input.tabIndex].subviews.first?.subviews {
            for subview in subviews where subview.tag == tag {
                subview.fadeOut() { _ in
                    subview.removeFromSuperview()
                }
            }
        }
    }

    /// Returns the DotView's Tag for the specified WooTab
    ///
    private func dotTag(for tab: WooTab) -> Int {
        return tab.identifierNumber + DotConstants.tagOffset
    }
}


// MARK: - Constants!
//
private extension NotificationsBadgeController {

    enum DotConstants {
        static let diameter    = CGFloat(9)
        static let borderWidth = CGFloat(1)
        static let xOffset     = CGFloat(16)
        static let yOffset     = CGFloat(0)
        static let tagOffset   = 999
    }
}
