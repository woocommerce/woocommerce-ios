import SwiftUI

class NewSimplePaymentsNoticeViewModel {

    let simplePaymentsNoticeView: NewSimplePaymentsNoticeView

    /// Redirects to `HubMenu`tabBar
    ///
    private var completionHandler: (() -> Void)? = {
        guard let mainTabBarController = AppDelegate.shared.tabBarController else {
            return
        }
        mainTabBarController.navigateTo(.hubMenu)
    }

    init() {
        simplePaymentsNoticeView = NewSimplePaymentsNoticeView(buttonTapped: completionHandler )
    }

    func setupNewSimplePaymentsNoticeView(for viewController: UIViewController) {
        let hostingController = UIHostingController(rootView: simplePaymentsNoticeView)
        viewController.addChild(hostingController)
        viewController.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: viewController)
        setupConstraints(for: hostingController, with: viewController)
    }

    func setupConstraints(for hostingController: UIHostingController<NewSimplePaymentsNoticeView>, with viewController: UIViewController) {
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
