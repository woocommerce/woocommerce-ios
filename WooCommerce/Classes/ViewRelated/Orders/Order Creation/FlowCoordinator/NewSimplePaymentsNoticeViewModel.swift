import SwiftUI

final class NewSimplePaymentsNoticeViewModel {
    private let simplePaymentsNoticeView: DismissableNoticeView

    /// Redirects to `HubMenu`tabBar
    ///
    private var completionHandler: (() -> Void)? = {
        guard let mainTabBarController = AppDelegate.shared.tabBarController else {
            return
        }
        mainTabBarController.navigateTo(.hubMenu)
    }

    init() {
        simplePaymentsNoticeView = DismissableNoticeView(
            buttonTapped: completionHandler,
            title: Localization.title,
            message: Localization.message,
            confirmationButtonMessage: Localization.confirmationButton
        )
    }

    func setupNewSimplePaymentsNoticeView(for viewController: UIViewController) {
        let hostingController = UIHostingController(rootView: simplePaymentsNoticeView)
        viewController.addChild(hostingController)
        viewController.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: viewController)
        setupConstraints(for: hostingController, with: viewController)
    }

    private func setupConstraints(for hostingController: UIHostingController<DismissableNoticeView>, with viewController: UIViewController) {
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.widthAnchor.constraint(equalTo: viewController.view.widthAnchor).isActive = true
        hostingController.view.heightAnchor.constraint(equalToConstant: viewController.view.intrinsicContentSize.height + Layout.verticalSpace).isActive = true
        hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor, constant: 0).isActive = true
    }
}

private extension NewSimplePaymentsNoticeViewModel {
    enum Localization {
        static let title = NSLocalizedString("Payments from the Menu tab",
                                             comment: "Title of the bottom announcement modal when a merchant taps on Simple Payment")
        static let message = NSLocalizedString("Now you can quickly access In-Person Payments and other features with ease.",
                                               comment: "Message of the bottom announcement modal when a merchant taps on Simple Payment")
        static let confirmationButton = NSLocalizedString("Got it!",
                                                          comment: "Confirmation text of the button on the bottom announcement modal" +
                                                          "when a merchant taps on Simple Payment")
    }
    enum Layout {
        static let verticalSpace: CGFloat = 160
    }
}
