import SwiftUI
import UIKit

struct AIAssistantChatNavHost<Content: View>: UIViewControllerRepresentable {

    let host: AIAssistantNavigationHost
    @ViewBuilder let content: () -> Content

    func makeUIViewController(context: Context) -> UINavigationController {
        let chatHosting = UIHostingController(rootView: content())
        chatHosting.view.backgroundColor = .clear
        let navigationController = UINavigationController(rootViewController: chatHosting)
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.delegate = context.coordinator
        host.attach(navigationController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        host.attach(uiViewController)
    }

    static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: Coordinator) {
        if coordinator.host?.navigationController === uiViewController {
            coordinator.host?.attach(nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(host: host)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate {
        weak var host: AIAssistantNavigationHost?

        init(host: AIAssistantNavigationHost) {
            self.host = host
        }

        func navigationController(_ navigationController: UINavigationController,
                                  willShow viewController: UIViewController,
                                  animated: Bool) {
            // Hide the nav bar on the chat root (its inner NavigationStack provides the toolbar);
            // show it on every pushed detail VC so the back button is visible.
            let isRoot = viewController === navigationController.viewControllers.first
            navigationController.setNavigationBarHidden(isRoot, animated: animated)
        }
    }
}
