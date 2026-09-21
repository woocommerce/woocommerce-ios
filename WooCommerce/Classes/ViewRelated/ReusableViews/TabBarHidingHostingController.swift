import SwiftUI
import UIKit

/// A `UIHostingController` base that hides the main tab bar while the screen is on screen.
///
/// `hidesBottomBarWhenPushed` (set here in `init`) only hides the tab bar for screens pushed onto a
/// navigation controller that is a direct child of the tab bar controller. Screens pushed inside a
/// SwiftUI `NavigationStack` (e.g. the Menu tab) live in a navigation controller that is not such a
/// direct child, so the flag is silently ignored and the tab bar stays visible (WOOMOB-3199). To cover
/// that case this base also hides the ancestor tab bar manually while the screen is shown and restores
/// its previous visibility when it leaves the navigation stack. Subclass this instead of
/// `UIHostingController` (and don't set `hidesBottomBarWhenPushed` again — it's set here).
class TabBarHidingHostingController<Content: View>: UIHostingController<Content> {

    /// The tab bar's visibility before this screen hid it, captured on the way in so it can be restored
    /// on the way out. `nil` while this controller is not managing the tab bar.
    private var tabBarWasHiddenBeforeAppearing: Bool?

    override init(rootView: Content) {
        super.init(rootView: rootView)
        hidesBottomBarWhenPushed = true
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let tabBar = tabBarController?.tabBar else {
            return
        }
        // Capture the prior visibility only on the way in, so re-appearing after a child is popped
        // (the chat/connectivity flows push children) doesn't overwrite it with the hidden state.
        if tabBarWasHiddenBeforeAppearing == nil {
            tabBarWasHiddenBeforeAppearing = tabBar.isHidden
        }
        setAncestorTabBar(hidden: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Only restore when actually leaving the stack — not when a child screen is pushed on top of us.
        guard let previousValue = tabBarWasHiddenBeforeAppearing,
              isMovingFromParent || isBeingDismissed else {
            return
        }

        // Restore the tab bar's previous visibility, keeping it hidden if an interactive pop is cancelled.
        guard let transitionCoordinator else {
            setAncestorTabBar(hidden: previousValue)
            tabBarWasHiddenBeforeAppearing = nil
            return
        }
        transitionCoordinator.animate(alongsideTransition: { [weak self] _ in
            self?.setAncestorTabBar(hidden: previousValue)
        }, completion: { [weak self] context in
            guard let self else {
                return
            }
            if context.isCancelled {
                self.setAncestorTabBar(hidden: true)
            } else {
                self.tabBarWasHiddenBeforeAppearing = nil
            }
        })
    }

    private func setAncestorTabBar(hidden: Bool) {
        guard let tabBar = tabBarController?.tabBar, tabBar.isHidden != hidden else {
            return
        }
        tabBar.isHidden = hidden
    }
}
