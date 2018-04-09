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
        setupTabBar()
    }

    func setupTabBar() {
        guard let items = tabBar.items else {
            fatalError()
        }
        
        for (index, item) in items.enumerated() {
            item.title = tabTitles[index]
            item.image = tabIcons[index]
        }
    }
}
