
import Foundation

/// NavigationCommand abstracts logic necessary provide clients of this library
/// with a way to navigate to a particular location in the UL navigation flow.
/// 
/// Concrete implementations of this protocol will decide what that means
///
protocol NavigationCommand {
    func execute(with: UINavigationController)
}
