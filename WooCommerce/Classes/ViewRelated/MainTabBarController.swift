import UIKit
import Gridicons

// Because Gridicons are programmatically created,
// we can't use Interface Builder to assign tab bar icons.
// We need a tab bar class to set them.
private enum TabTitles: String, CustomStringConvertible {
    case Dashboard
    case Orders
    case Notifications

    fileprivate var description: String {
        return self.rawValue
    }
}

private var tabIcons = [
    TabTitles.Dashboard: Gridicon.iconOfType(.statsAlt),
    TabTitles.Orders: Gridicon.iconOfType(.pages),
    TabTitles.Notifications: Gridicon.iconOfType(.bell)
]

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let tabBarItems = tabBar.items {
            for item in tabBarItems {
                if let title = item.title,
                    let tab = TabTitles(rawValue: title),
                    let glyph = tabIcons[tab] {
                        item.image = glyph
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
