import SwiftUI

class NewSimplePaymentsNoticeViewModel {

    let announcementView: AnnouncementBottomSheetView

    /// Redirects to `HubMenu`tabBar
    ///
    private var completionHandler: (() -> Void)? = {
        guard let mainTabBarController = AppDelegate.shared.tabBarController else {
            return
        }
        mainTabBarController.navigateTo(.hubMenu)
    }

    init() {
        announcementView = AnnouncementBottomSheetView(buttonTapped: completionHandler )
    }

    func setupNewSimplePaymentsNoticeView(for viewController: UIViewController) {
        let controller = UIHostingController(rootView: announcementView)
        viewController.addChild(controller)
        viewController.view.addSubview(controller.view)
        controller.didMove(toParent: viewController)
        setupConstraints(for: controller, with: viewController)
    }

    func setupConstraints(for hostingController: UIHostingController<AnnouncementBottomSheetView>, with viewController: UIViewController) {
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.widthAnchor.constraint(equalTo: viewController.view.widthAnchor).isActive = true
        hostingController.view.heightAnchor.constraint(equalToConstant: viewController.view.intrinsicContentSize.height + Layout.verticalSpace).isActive = true
        hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor, constant: 0).isActive = true
    }
}

private extension NewSimplePaymentsNoticeViewModel {
    enum Layout {
        static let verticalSpace: CGFloat = 160
    }
}
