import Foundation

public struct NavigateToEnterAccount: NavigationCommand {
    public init() {}
    public func execute(with: UINavigationController?) {
        print("Off we go to Enter a New WordPress.com account")
    }
}
