
import Foundation

public struct NavigateToEnterSite: NavigationCommand {
    public init() {}
    public func execute(with: UINavigationController?) {
        print("Off we go to Enter a New Site Address")
    }
}
