import SwiftUI
import UIKit

/// Hosting controller for the AI support chat view.
///
final class SupportChatHostingController: UIHostingController<SupportChatView> {

    private let viewModel: SupportChatViewModel

    init(viewModel: SupportChatViewModel) {
        self.viewModel = viewModel
        let view = SupportChatView(viewModel: viewModel)
        super.init(rootView: view)

        self.hidesBottomBarWhenPushed = true
        self.title = Localization.title
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
    }
}

// MARK: - Presentation
//
extension SupportChatHostingController {

    /// Shows the support chat from the given view controller.
    ///
    /// - Parameter presenter: The view controller to present from.
    func show(from presenter: UIViewController) {
        if let navigationController = presenter.navigationController {
            navigationController.pushViewController(self, animated: true)
        } else {
            let navigationController = UINavigationController(rootViewController: self)
            navigationController.modalPresentationStyle = .formSheet
            presenter.present(navigationController, animated: true)
        }
    }
}

// MARK: - Localization
//
private extension SupportChatHostingController {
    enum Localization {
        static let title = NSLocalizedString(
            "supportChatHostingController.title",
            value: "Chat with Support",
            comment: "Navigation title for the AI support chat screen"
        )
    }
}
