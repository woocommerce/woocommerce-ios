import UIKit
import Gridicons


// MARK: - MainTabBarController
//
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
