import UIKit

@MainActor
final class AIAssistantNavigationHost {
    private(set) weak var navigationController: UINavigationController?

    func attach(_ navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
}
