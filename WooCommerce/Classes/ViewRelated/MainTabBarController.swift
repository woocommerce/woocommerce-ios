import UIKit
import Gridicons

/// Because Gridicons are programmatically created,
/// we can't use Interface Builder to assign tab bar icons.
/// We need a tab bar class to set them.
///
class MainTabBarController: UITabBarController {

    private var tabTitles = [
        NSLocalizedString("Dashboard", comment: "Dashboard tab title"),
        NSLocalizedString("Orders", comment: "Orders tab title"),
        NSLocalizedString("Notifications", comment: "Notifications tab title")
    ]

    private var tabIcons = [
        Gridicon.iconOfType(.statsAlt),
        Gridicon.iconOfType(.pages),
        Gridicon.iconOfType(.bell)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        if let tabBarItems = tabBar.items {
            for i in 0..<tabBarItems.count {
                let item = tabBarItems[i]
                item.title = tabTitles[i]
                item.image = tabIcons[i]
            }
        }
    }
}
